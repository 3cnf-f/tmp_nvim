import pandas as pd


def export_to_csv(obj, filename):
    """Convert ``obj`` to a pandas DataFrame and write it to ``filename``.

    Supported input types: list, tuple, set, dict, pandas.DataFrame.
    Returns the path written.
    """
    if obj is None:
        raise ValueError("obj is None — nothing to export")

    if isinstance(obj, pd.DataFrame):
        df = obj
    elif isinstance(obj, list):
        df = pd.DataFrame(obj)
    elif isinstance(obj, tuple):
        df = pd.DataFrame(list(obj))
    elif isinstance(obj, set):
        df = pd.DataFrame(list(obj))
    elif isinstance(obj, dict):
        try:
            df = pd.DataFrame(obj)
        except ValueError:
            df = pd.DataFrame([obj])
    else:
        raise TypeError(
            f"unsupported type: {type(obj).__name__} "
            "(supported: list, tuple, set, dict, pandas.DataFrame)"
        )

    if not filename.endswith(".csv"):
        filename += ".csv"

    df.to_csv(filename, index=False)
    return filename
