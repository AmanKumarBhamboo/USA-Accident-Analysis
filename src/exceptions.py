import sys


class USAccidentException(Exception):
    def __init__(self, message, error_detail: Exception = None):
        super().__init__(message)
        self.error_detail = error_detail

    def __str__(self):
        if self.error_detail:
            return f"{self.args[0]}\nCaused by: {type(self.error_detail).__name__}: {self.error_detail}"
        return self.args[0]


class DataIngestionError(USAccidentException):
    pass


class DataTransformationError(USAccidentException):
    pass
