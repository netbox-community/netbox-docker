from typing import Tuple


def split_params(params: dict, unique_params: list = None) -> Tuple[dict, dict]:
    """Split params dict into dict with matching params and a dict with default values"""

    if unique_params is None:
        unique_params = ["name", "slug"]

    matching_params = {}
    for unique_param in unique_params:
        param = params.pop(unique_param, None)
        if param:
            matching_params[unique_param] = param
    return matching_params, params
