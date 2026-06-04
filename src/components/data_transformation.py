import os
import re
import json
import pandas as pd
from src.logger import setup_logger
from src.exceptions import DataTransformationError


class DataTransformation:
    def __init__(self, config):
        self.config = config
        cfg = config['data_ingestion']
        self.artifacts_folder = cfg['artifacts_folder']
        self.raw_data_folder = cfg['raw_data_folder']
        self._transformed_dfs = {}
        log_dir = cfg.get('log_folder', 'logs')
        self.logger = setup_logger('data_transformation', log_dir)

    @staticmethod
    def to_snake_case(name):
        name = name.strip()
        name = re.sub(r'[^a-zA-Z0-9\s]', '', name)
        name = re.sub(r'[\s]+', '_', name)
        name = re.sub(r'_+', '_', name)
        return name.lower().strip('_')

    def _build_info(self, filename, df, transformed_filename):
        return {
            'file': filename,
            'transformed_file': transformed_filename,
            'shape': list(df.shape),
            'columns': [
                {
                    'name': col,
                    'dtype': str(df[col].dtype),
                    'null_count': int(df[col].isna().sum()),
                    'null_pct': round(float(df[col].isna().mean() * 100), 2)
                }
                for col in df.columns
            ]
        }

    def run(self, file_paths):
        self.logger.info("Data transformation started")
        os.makedirs(self.artifacts_folder, exist_ok=True)

        merge_config = self.config.get('data_ingestion', {}).get('merge', {})
        merge_enabled = merge_config.get('enabled', False)
        self._transformed_dfs = {}

        for filepath in file_paths:
            filename = os.path.basename(filepath)
            self.logger.info("Reading %s", filename)

            try:
                df = pd.read_csv(filepath, low_memory=False)
                self.logger.info("Loaded %s with shape %s", filename, df.shape)

                df.columns = [self.to_snake_case(col) for col in df.columns]

                base, ext = os.path.splitext(filename)
                transformed_filename = f"{base}_transformed{ext}"
                self._transformed_dfs[transformed_filename] = df

                info = self._build_info(filename, df, transformed_filename)

                if not merge_enabled:
                    dest = os.path.join(self.artifacts_folder, f"transformed__{filename}")
                    df.to_csv(dest, index=False)
                    self.logger.info("Saved -> %s", dest)

                    info_path = os.path.join(self.artifacts_folder, f"{base}_info.json")
                    with open(info_path, 'w') as f:
                        json.dump(info, f, indent=2)
                    self.logger.info("Info saved -> %s", info_path)

            except Exception as e:
                raise DataTransformationError(f"Failed to transform {filename}", e) from e

        self.logger.info("Data transformation completed")
        return self._transformed_dfs

    def merge(self):
        if not self._transformed_dfs:
            self.logger.info("No transformed data to merge, skipping.")
            return None

        merge_config = self.config.get('data_ingestion', {}).get('merge', {})
        enabled = merge_config.get('enabled', False)
        files_to_merge = merge_config.get('files', [])

        if not enabled or not files_to_merge:
            self.logger.info("Merge disabled or no files specified, skipping.")
            return None

        self.logger.info("Merge started with %d files", len(files_to_merge))

        frames = []
        reference_columns = None

        for filename in files_to_merge:
            if filename not in self._transformed_dfs:
                self.logger.warning("Transformed data not found for %s, skipping.", filename)
                continue

            df = self._transformed_dfs[filename]
            cols = list(df.columns)

            if reference_columns is None:
                reference_columns = cols
            elif cols != reference_columns:
                raise DataTransformationError(
                    f"Cannot merge {filename}: columns do not match. "
                    f"Expected {reference_columns}, got {cols}"
                )

            self.logger.info("Loaded %s with shape %s", filename, df.shape)
            frames.append(df)

        if not frames:
            self.logger.warning("No files loaded for merge.")
            return None

        merged_df = pd.concat(frames, ignore_index=True)

        merged_path = os.path.join(self.artifacts_folder, "merged.csv")
        merged_df.to_csv(merged_path, index=False)
        self.logger.info("Merged %d files into %s with shape %s",
                         len(frames), merged_path, merged_df.shape)

        merged_info = {
            'merged_file': 'merged.csv',
            'files_merged': files_to_merge,
            'shape': list(merged_df.shape),
            'columns': [
                {
                    'name': col,
                    'dtype': str(merged_df[col].dtype),
                    'null_count': int(merged_df[col].isna().sum()),
                    'null_pct': round(float(merged_df[col].isna().mean() * 100), 2)
                }
                for col in merged_df.columns
            ]
        }

        info_path = os.path.join(self.artifacts_folder, "merged_info.json")
        with open(info_path, 'w') as f:
            json.dump(merged_info, f, indent=2)
        self.logger.info("Merge info saved -> %s", info_path)

        self.logger.info("Merge completed")
        return merged_path
