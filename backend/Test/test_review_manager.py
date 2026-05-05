import os
import sys
import unittest
from unittest.mock import patch

from flask import Flask

CURRENT_DIR = os.path.dirname(__file__)
BACKEND_DIR = os.path.abspath(os.path.join(CURRENT_DIR, os.pardir))
if BACKEND_DIR not in sys.path:
    sys.path.insert(0, BACKEND_DIR)

import review_manager
from review_manager import ReviewManager


class DummyResponse:
    def __init__(self, data=None):
        self.data = data or []


class FakeSelectTable:
    def __init__(self, data):
        self._data = data

    def select(self, *_args, **_kwargs):
        return self

    def eq(self, *_args, **_kwargs):
        return self

    def order(self, *_args, **_kwargs):
        return self

    def execute(self):
        return DummyResponse(self._data)


class FakeReadClient:
    def __init__(self, data):
        self._data = data

    def table(self, _name):
        return FakeSelectTable(self._data)


class FakeInsertTable:
    def __init__(self):
        self.inserted = None

    def insert(self, payload):
        self.inserted = payload
        return self

    def execute(self):
        return DummyResponse([self.inserted])


class FakeWriteClient:
    def __init__(self):
        self.table_ref = FakeInsertTable()

    def table(self, _name):
        return self.table_ref


class ReviewManagerTests(unittest.TestCase):
    def setUp(self):
        self.app = Flask(__name__)
        self.manager = ReviewManager()

    def test_get_returns_reviews_for_email(self):
        fake_rows = [
            {
                "title": "Gunwharf Quays",
                "review": 5,
                "comment": "Clean and secure.",
                "user_email": "test@example.com",
                "user_name": "Test User",
                "created_at": "2026-04-29T12:00:00+00:00",
            }
        ]

        with patch.object(
            review_manager,
            "get_database_connection",
            return_value=FakeReadClient(fake_rows),
        ):
            with self.app.test_request_context("/review?email=test@example.com"):
                body, status_code = self.manager.get()

        self.assertEqual(status_code, 200)
        self.assertEqual(body["data"][0]["title"], "Gunwharf Quays")
        self.assertEqual(body["data"][0]["user_name"], "Test User")
        self.assertEqual(body["data"][0]["comment"], "Clean and secure.")

    def test_get_requires_email_query_param(self):
        fake_rows = [
            {
                "title": "Gunwharf Quays",
                "review": 5,
                "comment": "Clean and secure.",
                "user_email": "other@example.com",
                "user_name": "Other User",
                "created_at": "2026-04-29T12:00:00+00:00",
            }
        ]

        with patch.object(
            review_manager,
            "get_database_connection",
            return_value=FakeReadClient(fake_rows),
        ):
            with self.app.test_request_context("/review"):
                body, status_code = self.manager.get()

        self.assertEqual(status_code, 200)
        self.assertEqual(len(body["data"]), 1)
        self.assertEqual(body["data"][0]["user_name"], "Other User")

    def test_post_stores_review_metadata(self):
        fake_client = FakeWriteClient()

        with patch.object(
            review_manager,
            "get_database_connection_admin",
            return_value=fake_client,
        ):
            with self.app.test_request_context(
                "/review",
                json={
                    "title": "Gunwharf Quays",
                    "review": 4,
                    "comment": "Easy parking and well lit.",
                    "user_email": "test@example.com",
                    "user_name": "Test User",
                },
            ):
                body, status_code = self.manager.post()

        self.assertEqual(status_code, 201)
        self.assertEqual(body["message"], "Review submitted successfully")
        self.assertEqual(fake_client.table_ref.inserted["title"], "Gunwharf Quays")
        self.assertEqual(
            fake_client.table_ref.inserted["comment"], "Easy parking and well lit."
        )
        self.assertEqual(
            fake_client.table_ref.inserted["user_email"], "test@example.com"
        )
        self.assertEqual(fake_client.table_ref.inserted["user_name"], "Test User")


if __name__ == "__main__":
    unittest.main()
