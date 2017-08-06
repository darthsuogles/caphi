FROM caffe2ai/caffe2:c2.cpu.min.ubuntu14.04

#RUN apt-get update && apt-get install -y emacs-nox
RUN pip2 install -U ipython
RUN pip2 install -U numpy scipy pandas pyarrow

WORKDIR /app
COPY entrypoint.sh .
WORKDIR /.ipy.conf
COPY ipython_config.py .

ENTRYPOINT /app/entrypoint.sh
