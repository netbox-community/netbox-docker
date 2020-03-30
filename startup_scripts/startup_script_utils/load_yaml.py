from ruamel.yaml import YAML
from pathlib import Path

def load_yaml(yaml_file: str):
  yf = Path(yaml_file)
  if not yf.is_file():
    return None
  with yf.open("r") as stream:
    yaml = YAML(typ="safe")
    return yaml.load(stream)
