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

# 2. Connect to Nvim
try:
    nv = pynvim.attach('socket', path='/tmp/nvimsocket')
    print("Connected to Neovim successfully.")
except Exception as e:
    print(f"Connection failed: {e}")

def debug_sync_to_nvim(result):
    if result.result is None or 'nv' not in globals():
        return
    
    data = result.result
    
    # 3. Formatting Logic
    if has_rich:
        # Use Rich to create a clean, indented string
        console = Console(file=io.StringIO(), force_terminal=False, width=100)
        console.print(Pretty(data, indent_guides=False, max_length=20, max_depth=5))
        formatted_text = console.file.getvalue()
    else:
        # Fallback to standard pprint
        import pprint
        formatted_text = pprint.pformat(data, indent=2)

    lines = formatted_text.splitlines()

    # 4. Update Nvim Buffer
    # Clear and replace entire buffer
    nv.api.buf_set_lines(0, 0, -1, False, lines)
    
    # 5. Set Highlighting
    # If it looks like a dict/list, try JSON highlighting, else Python
    ft = 'json' if isinstance(data, (dict, list)) else 'python'
    nv.api.set_option_value('filetype', ft, {'buf': 0})
    
    # Scroll to top for visibility
    nv.command("normal! gg")

# 6. Safe Event Registration
ip = get_ipython()
if ip:
    try:
        ip.events.unregister('post_run_cell', debug_sync_to_nvim)
    except (ValueError, NameError):
        pass
    ip.events.register('post_run_cell', debug_sync_to_nvim)
    print("Hook registered. Try running: {'a': [1, 2, 3], 'b': {'c': 'd'}}")
