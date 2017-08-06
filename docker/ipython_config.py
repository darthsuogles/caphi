c = get_config()

c.IPythonTerminalApp.display_banner = True
c.InteractiveShellApp.log_level = 20
c.InteractiveShellApp.exec_lines = [
    'from __future__ import absolute_import',
    'from __future__ import division',
    'from __future__ import print_function',
    'from __future__ import unicode_literals',
    'import numpy as np',
    'import scipy as sp',
    'import pyarrow as pa',
    'from caffe2.python import core, workspace',
    'from caffe2.proto import caffe2_pb2',
]
c.InteractiveShell.banner2 = "@ Caffe2"
c.InteractiveShell.autoindent = True
c.InteractiveShell.colors = 'LightBG'
c.InteractiveShell.confirm_exit = False
c.InteractiveShell.deep_reload = True
c.InteractiveShell.prompts_pad_left = True
c.InteractiveShell.xmode = 'Context'

c.PrefilterManager.multi_line_specials = True

c.AliasManager.user_aliases = [
 ('la', 'ls -al')
]
