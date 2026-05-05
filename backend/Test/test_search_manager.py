import os
import sys
import unittest
from unittest.mock import patch

from flask import Flask

CURRENT_DIR = os.path.dirname(__file__)
BACKEND_DIR = os.path.abspath(os.path.join(CURRENT_DIR, os.pardir))
if BACKEND_DIR not in sys.path:
    sys.path.insert(0, BACKEND_DIR)

import search_manager
from search_manager import SearchManager, extract_distance, to_float, within_range


class DummyResponse:
    def __init__(self, data=None, error=None):
        self.data = data or []
        self.error = error


class FakeSupabaseTable:
    def __init__(self, data):
        self._data = data

    def select(self, *_args, **_kwargs):
        return self

    def execute(self):
        return DummyResponse(self._data)


class FakeSupabaseClient:
    def __init__(self, data):
        self._data = data

    def table(self, _name):
        return FakeSupabaseTable(self._data)


class SearchManagerTests(unittest.TestCase):
    def setUp(self):
        self.app = Flask(__name__)
        self.manager = SearchManager()

    def test_to_float(self):
        self.assertEqual(to_float("12.5"), 12.5)
        self.assertEqual(to_float(7), 7.0)
        self.assertIsNone(to_float("not-a-number"))

    def test_within_range(self):
        self.assertTrue(within_range(5, 0, 10))
        self.assertFalse(within_range(None, 0, 10))
        self.assertFalse(within_range(11, 0, 10))

    def test_extract_distance_uses_existing_distance_first(self):
        car_park = {"distance": "4.2"}
        self.assertEqual(extract_distance(car_park, 0, 0), 4.2)

    def test_extract_distance_computes_distance_when_coordinates_exist(self):
        car_park = {"longitude": 0.1, "latitude": 0.1}
        distance = extract_distance(car_park, 0.0, 0.0)
        self.assertIsNotNone(distance)
        self.assertGreater(distance, 0)

    def test_get_filters_by_all_fields(self):
        sample_data = [
            {
                "carpark_id": 1,
                "name": "Gunwharf Quays",
                "price": 6.0,
                "avg_rating": 4.5,
                "longitude": -1.091,
                "latitude": 50.796,
            },
            {
                "carpark_id": 2,
                "name": "Far Away Parking",
                "price": 3.0,
                "avg_rating": 4.8,
                "longitude": -2.5,
                "latitude": 51.5,
            },
            {
                "carpark_id": 3,
                "name": "Gunwharf Budget",
                "price": 20.0,
                "avg_rating": 4.9,
                "longitude": -1.091,
                "latitude": 50.796,
            },
        ]

        with patch.object(search_manager, "get_database_connection", return_value=FakeSupabaseClient(sample_data)):
            with self.app.test_request_context(
                "/search?query=gunwharf&minPrice=0&maxPrice=10&minRating=4&maxRating=5&minDistance=0&maxDistance=5&longitude=-1.091&latitude=50.796"
            ):
                result, status_code = self.manager.get()

        self.assertEqual(status_code, 200)
        self.assertEqual(len(result), 1)
        self.assertEqual(result[0]["name"], "Gunwharf Quays")

    def test_get_rejects_invalid_price_range(self):
        with self.app.test_request_context(
            "/search?query=test&minPrice=10&maxPrice=5&minRating=0&maxRating=5&minDistance=0&maxDistance=10&longitude=0&latitude=0"
        ):
            result, status_code = self.manager.get()

        self.assertEqual(status_code, 400)
        self.assertIn("minPrice cannot be greater than maxPrice", result["error"])


if __name__ == "__main__":
    unittest.main()
