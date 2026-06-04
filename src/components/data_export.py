import os
import pandas as pd
from src.logger import setup_logger


class DataExport:
    def __init__(self, config):
        self.config = config
        cfg = config['data_ingestion']
        self.artifacts_folder = cfg['artifacts_folder']
        log_dir = cfg.get('log_folder', 'logs')
        self.logger = setup_logger('data_export', log_dir)

    def run(self):
        pg_config = self.config.get('postgres', {})
        if not pg_config.get('database'):
            self.logger.info("No database configured, skipping Postgres export.")
            return

        export_config = self.config.get('export', {})
        schema_name = export_config.get('schema', 'crime_data')

        try:
            from sqlalchemy import create_engine, text
        except ImportError:
            self.logger.warning("sqlalchemy not installed. Run: uv add sqlalchemy psycopg2-binary")
            return

        host = pg_config.get('host', 'localhost')
        port = pg_config.get('port', 5432)
        database = pg_config.get('database')
        username = pg_config.get('username', '')
        password = pg_config.get('password', '')

        conn_str = f"postgresql://{username}:{password}@{host}:{port}/{database}"
        engine = create_engine(conn_str)
        self.logger.info("Connected to PostgreSQL: %s:%s/%s", host, port, database)

        with engine.connect() as conn:
            conn.execute(text(f"CREATE SCHEMA IF NOT EXISTS {schema_name}"))
            conn.commit()

        merged_file = os.path.join(self.artifacts_folder, 'merged.csv')

        if os.path.exists(merged_file):
            table_name = export_config.get('merged_table_name', 'crime_combined')
            self.logger.info("Merge detected — exporting merged file only")
            self._export_table(engine, schema_name, table_name, merged_file)
        else:
            files = sorted([
                f for f in os.listdir(self.artifacts_folder)
                if f.startswith('transformed__') and f.endswith('.csv')
            ])
            if not files:
                self.logger.warning("No transformed files found in %s", self.artifacts_folder)
                engine.dispose()
                return

            self.logger.info("No merge — exporting individual transformed files")
            for filename in files:
                table_name = filename.replace('transformed__', '').replace('.csv', '').lower()
                file_path = os.path.join(self.artifacts_folder, filename)
                self._export_table(engine, schema_name, table_name, file_path)

        engine.dispose()
        self.logger.info("Postgres export completed")

    def _export_table(self, engine, schema, table_name, file_path):
        self.logger.info("Exporting %s -> %s.%s", file_path, schema, table_name)
        df = pd.read_csv(file_path, low_memory=False)
        df.to_sql(table_name, engine, schema=schema,
                  if_exists='replace', index=False, method='multi', chunksize=1000)
        self.logger.info("Exported %s with shape %s", table_name, df.shape)
