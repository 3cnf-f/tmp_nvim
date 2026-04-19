import pynvim
import io
import sys
from IPython import get_ipython

# 1. Initialize Rich (Modern beautifier)
try:
    from rich.console import Console
    from rich.pretty import Pretty
    has_rich = True
except ImportError:
    import pprint
    has_rich = False

# 2. Connect to Main Nvim
try:
    nv = pynvim.attach('socket', path='/tmp/nvimsocket')
    print("Connected to Neovim successfully.")
except Exception as e:
    print(f"Connection failed: {e}")

# New: Connect to Left/Right sockets (lazy init)
nv_left = None
nv_right = None

def connect_side(socket_path, var_name):
    global nv_left, nv_right
    try:
        if var_name == 'left':
            nv_left = pynvim.attach('socket', path=socket_path)
            print(f"Connected to {socket_path} (left) successfully.")
        elif var_name == 'right':
            nv_right = pynvim.attach('socket', path=socket_path)
            print(f"Connected to {socket_path} (right) successfully.")
    except Exception as e:
        print(f"Connection to {socket_path} failed: {e}")

# Helper: Format data (shared logic)
def format_data(data):
    if has_rich:
        console = Console(file=io.StringIO(), force_terminal=False, width=100)
        console.print(Pretty(data, indent_guides=False, max_length=20, max_depth=5))
        formatted_text = console.file.getvalue()
    else:
        import pprint
        formatted_text = pprint.pformat(data, indent=2)
    return formatted_text.splitlines()

# New: Send to left socket (/tmp/nvimsleft, buffer 0)
def debug_sync_to_nvim(result):
    if result.result is None or 'nv' not in globals():
        return
    data = result.result
    lines = format_data(data)  # Reuse helper
    nv.api.buf_set_lines(0, 0, -1, False, lines)
    ft = 'json' if isinstance(data, (dict, list)) else 'python'
    nv.api.set_option_value('filetype', ft, {'buf': 0})
    nv.command("normal! gg")
def l_soc(results):
    global nv_left
    if results is None:
        print("No results.")
        return
    data = results
    lines = format_data(data)
    ft = 'json' if isinstance(data, (dict, list)) else 'python'
    
    max_retries = 2
    for attempt in range(max_retries + 1):
        try:
            if nv_left is None:
                connect_side('/tmp/nvimsleft', 'left')
            if nv_left is None:
                print("Failed to connect to left socket.")
                return
            nv_left.api.buf_set_lines(0, 0, -1, False, lines)
            nv_left.api.set_option_value('filetype', ft, {'buf': 0})
            nv_left.command("normal! gg")
            print("l_soc updated successfully.")  # Optional feedback
            return
        except (OSError, EOFError) as e:
            print(f"l_soc error (attempt {attempt + 1}): {e}. Reconnecting...")
            nv_left = None  # Force reconnect
        except Exception as e:
            print(f"l_soc unexpected error: {e}")
            return
    print("l_soc failed after retries.")

# New: Send to right socket (/tmp/nvimsright, buffer 0) - with reconnect
def r_soc(results):
    global nv_right
    if results is None:
        print("No results.")
        return
    data = results
    lines = format_data(data)
    ft = 'json' if isinstance(data, (dict, list)) else 'python'
    
    max_retries = 2
    for attempt in range(max_retries + 1):
        try:
            if nv_right is None:
                connect_side('/tmp/nvimsright', 'right')
            if nv_right is None:
                print("Failed to connect to right socket.")
                return
            nv_right.api.buf_set_lines(0, 0, -1, False, lines)
            nv_right.api.set_option_value('filetype', ft, {'buf': 0})
            nv_right.command("normal! gg")
            print("r_soc updated successfully.")  # Optional feedback
            return
        except (OSError, EOFError) as e:
            print(f"r_soc error (attempt {attempt + 1}): {e}. Reconnecting...")
            nv_right = None  # Force reconnect
        except Exception as e:
            print(f"r_soc unexpected error: {e}")
            return
    print("r_soc failed after retries.")

# 6. Safe Event Registration
ip = get_ipython()
if ip:
    try:
        ip.events.unregister('post_run_cell', debug_sync_to_nvim)
    except (ValueError, NameError):
        pass
    ip.events.register('post_run_cell', debug_sync_to_nvim)
    print("Hook registered. Try running: {'a': [1, 2, 3], 'b': {'c': 'd'}}")
    print("New functions: l_soc(results), r_soc(results). Connect first with connect_side('/tmp/nvimsleft', 'left') etc.[file:1]")

# s.connect_side('/tmp/nvimsleft', 'left')
# s.connect_side('/tmp/nvimsright', 'right')

