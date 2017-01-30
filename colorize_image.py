import numpy as np
import matplotlib.pyplot as plt
import os
from pathlib import Path
import skimage.color as color
import scipy.ndimage.interpolation as sni
import caffe

plt.rcParams['figure.figsize'] = (12, 6)
caffe.set_mode_cpu()

fp_vision = Path.cwd() / '..' / 'vision'
fp_auto_color = fp_vision / 'auto_color' / 'colorization'

nnet = caffe.Net(
    str(fp_auto_color / 'models' / 'colorization_deploy_v2.prototxt'),
    str(fp_auto_color / '..' / 'colorization_release_v2.caffemodel'),
    caffe.TEST)

H_in, W_in = nnet.blobs['data_l'].data.shape[2:]
H_out, W_out = nnet.blobs['class8_ab'].data.shape[2:]
print('Input dims: {}, {}'.format(H_in, W_in))
print('Output dims: {}, {}'.format(H_out, W_out))

pts_in_hull = np.load(str(fp_auto_color / 'resources' / 'pts_in_hull.npy'))
nnet.params['class8_ab'][0].data[:, :, 0, 0] = pts_in_hull.transpose((1,0))


def colorize_image(fp_img: Path): 
    img_rgb = caffe.io.load_image(str(fp_img))
    img_lab = color.rgb2lab(img_rgb)
    img_l = img_lab[:, :, 0]
    H_orig, W_orig = img_rgb.shape[:2]

    img_lab_bw = img_lab.copy()
    img_lab_bw[:, :, 1:] = 0
    img_rgb_bw = color.lab2rgb(img_lab_bw)

    img_rs = caffe.io.resize_image(img_rgb, (H_in, W_in))
    img_lab_rs = color.rgb2lab(img_rs)
    img_l_rs = img_lab_rs[:, :, 0]

    # Colorization
    nnet.blobs['data_l'].data[0, 0, :, :] = img_l_rs - 50  # mean subtraction
    nnet.forward()

    ab_dec = nnet.blobs['class8_ab'].data[0, :, :, :].transpose((1, 2, 0))
    ab_dec_us = sni.zoom(ab_dec, 
                         (1. * H_orig / H_out, 1. * W_orig / W_out, 1))
    img_lab_out = np.concatenate(
        (img_l[:, :, np.newaxis], ab_dec_us), axis=2)
    img_rgb_out = np.clip(color.lab2rgb(img_lab_out), 0, 1)

    # Show them side-by-side
    img_pad = np.ones((H_orig, W_orig // 10, 3))
    plt.imshow(np.hstack((img_rgb, img_pad, img_rgb_bw, img_pad, img_rgb_out)))
    plt.title('(Left) Loaded image   /   (Middle) Input  /  (Right) Colorized')
    plt.axis('off')


fp_img = fp_auto_color / 'demo' / 'imgs' / 'ansel_adams3.jpg'
#fp_img = Path.home() / 'Downloads' / 'Cat-hd-wallpapers.jpg'
#fp_img = Path.home() / 'Downloads' / 'IMG_3553.jpg'
colorize_image(fp_img)
 
