import os
from src.logger import setup_logger


class DataIngestion:
    def __init__(self, config):
        self.config = config
        cfg = config['data_ingestion']
        self.raw_data_folder = cfg['raw_data_folder']
        self.files_to_process = cfg.get('files_to_process', [])
        log_dir = cfg.get('log_folder', 'logs')
        self.logger = setup_logger('data_ingestion', log_dir)

    def run(self):
        self.logger.info("Data ingestion started")

        files = self.files_to_process
        if not files:
            files = sorted([
                f for f in os.listdir(self.raw_data_folder)
                if f.endswith(('.csv', '.parquet', '.json'))
            ])

        file_paths = []
        for filename in files:
            path = os.path.join(self.raw_data_folder, filename)
            if not os.path.exists(path):
                self.logger.warning("%s not found, skipping.", path)
                continue
            file_paths.append(path)
            self.logger.info("Found %s", path)

        self.logger.info("Data ingestion completed: %d files found", len(file_paths))
        return file_paths
