import requests
import yaml
import zipfile
import io
from pathlib import Path


def run():
    with open("config/columns.yaml", "r") as f:
        config = yaml.safe_load(f)

    url = config["source_url"]
    save_path = Path(config["raw_file_path"])
    save_path.parent.mkdir(parents=True, exist_ok=True)

    print(f"Downloading from {url}...")

    response = requests.get(url)
    response.raise_for_status()

    # Check if the response is a ZIP file
    if zipfile.is_zipfile(io.BytesIO(response.content)):
        print("ZIP file detected. Extracting CSV...")

        with zipfile.ZipFile(io.BytesIO(response.content)) as z:
            csv_files = [f for f in z.namelist() if f.endswith(".csv")]

            if not csv_files:
                raise FileNotFoundError("No CSV file found inside the ZIP archive.")

            csv_name = csv_files[0]

            with z.open(csv_name) as source, open(save_path, "wb") as target:
                target.write(source.read())

        print(f"CSV extracted and saved to {save_path}")

    else:
        with open(save_path, "wb") as f:
            f.write(response.content)

        print(f"CSV saved to {save_path}")


if __name__ == "__main__":
    run()