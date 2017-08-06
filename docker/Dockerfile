FROM caffe2ai/caffe2:c2.cpu.min.ubuntu14.04

RUN pip2 install -U ipython
COPY entrypoint.sh /app_exec

ENTRYPOINT /app_exec
