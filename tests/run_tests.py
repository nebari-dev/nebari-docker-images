import sys
import argparse
import logging as log
from typing import NoReturn
import pytest

_LOGGER = log.getLogger(__name__)


def run_test(image_name: str, ex_timeout: str, retention_logs: list) -> NoReturn:
    """
    Runs a test module based on the provided image name.

    Args:
        image (str): The image name to run the test on. Will be used to derive the test suit directory.
        ex_timeout (str): The timeout for the test.
        retention_logs (bool): Whether or not to retain the logs artifact as part of the pipeline.

    Returns:
        Termination process code.
    """

    _LOGGER.info(f"Testing image: {image_name}")

    ret_code = pytest.main([
        "--numprocesses",
        "auto",
        "-m",
        "not info",
        f"tests/{image_name}",
    ])

    return sys.exit(ret_code)


if __name__ == "__main__":
    log.basicConfig(level=log.INFO)

    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument(
        "--image-name",
        required=True,
        help="Specify the image name to run the test on",
    )

    arg_parser.add_argument(
        "--timeout",
        required=False,
        default=1600,
        help="Specify the timeout for the test",
    )

    arg_parser.add_argument(
        "--retention-logs",
        required=False,
        default=False,
        help="Specify if the logs should be retained as CI artifacts",
    )

    args = arg_parser.parse_args()

    # Run tests based on the image name
    run_test(
        image_name = args.image_name,
        ex_timeout = args.timeout,
        retention_logs = args.retention_logs,
    )