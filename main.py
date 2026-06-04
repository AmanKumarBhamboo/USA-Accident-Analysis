import os
import sys
import yaml
from src.logger import setup_logger
from src.exceptions import USAccidentException
from src.components.data_ingestion import DataIngestion
from src.components.data_transformation import DataTransformation
from src.components.data_export import DataExport


def load_config(path="config/config.yaml"):
    with open(path, 'r') as f:
        return yaml.safe_load(f)


def main():
    config = load_config()
    cfg = config['data_ingestion']
    log_dir = cfg.get('log_folder', 'logs')
    logger = setup_logger('pipeline', log_dir)

    logger.info("Pipeline started")

    try:
        logger.info("=== Step 1: Data Ingestion ===")
        ingestor = DataIngestion(config)
        file_paths = ingestor.run()

        logger.info("=== Step 2: Data Transformation ===")
        transformer = DataTransformation(config)
        transformer.run(file_paths)

        logger.info("=== Step 3: Merge (if enabled) ===")
        merged_path = transformer.merge()

        logger.info("=== Step 4: Export to PostgreSQL ===")
        exporter = DataExport(config)
        exporter.run()

        logger.info("Pipeline completed successfully")
        if merged_path:
            logger.info("  Output: %s (merged)", merged_path)
        else:
            logger.info("  Output: artifacts/ (transformed files)")

    except USAccidentException as e:
        logger.error("Pipeline failed: %s", e)
        sys.exit(1)
    except Exception as e:
        logger.error("Unexpected error: %s", e)
        sys.exit(1)


if __name__ == "__main__":
    main()
