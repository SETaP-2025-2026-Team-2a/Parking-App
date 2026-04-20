
import sys
import os
import jwt
from datetime import datetime, timezone

CURRENT_DIR = os.path.dirname(__file__)
BACKEND_DIR = os.path.abspath(os.path.join(CURRENT_DIR, os.pardir))
if BACKEND_DIR not in sys.path:
    sys.path.insert(0, BACKEND_DIR)
    
import authentication_manager as am

class FakeResponse:
    def __init__(self, data=None, error=None):
        self.data = data or []
        self.error = error


class FakeError:
    def __init__(self, message="boom"):
        self.message = message


class FakeTable:
    def __init__(self, response):
        self._response = response
        self.calls = []

    def select(self, *_args, **_kwargs):
        self.calls.append("select")
        return self

    def delete(self, *_args, **_kwargs):
        self.calls.append("delete")
        return self

    def eq(self, *_args, **_kwargs):
        self.calls.append("eq")
        return self

    def execute(self):
        self.calls.append("execute")
        return self._response


class FakeSupabase:
    def __init__(self, response):
        self._response = response
        self.table_name = None
        self.table_obj = FakeTable(response)

    def table(self, name):
        self.table_name = name
        return self.table_obj


def test_create_session_token_contains_expected_claims(monkeypatch):
    monkeypatch.setattr(am, "JWT_SECRET", "test-secret")
    monkeypatch.setattr(am, "JWT_ALGORITHM", "HS256")
    monkeypatch.setattr(am, "JWT_EXPIRES_MINUTES", 15)

    user = {"email": "a@b.com", "name": "Ana", "lastname": "Doe"}
    token = am.create_session_token(user)

    payload = jwt.decode(token, "test-secret", algorithms=["HS256"])
    assert payload["sub"] == "a@b.com"
    assert payload["name"] == "Ana"
    assert payload["lastname"] == "Doe"
    assert payload["exp"] > payload["iat"]


def test_get_user_success(monkeypatch):
    response = FakeResponse(
        data=[{"name": "Ana", "lastname": "Doe", "email": "a@b.com", "password_hash": "hash"}],
        error=None,
    )
    fake_db = FakeSupabase(response)
    monkeypatch.setattr(am, "get_database_connection", lambda: fake_db)

    result = am.getUser("a@b.com")

    assert result["result"] is True
    assert result["email"] == "a@b.com"
    assert result["name"] == "Ana"
    assert result["password_hash"] == "hash"
    assert fake_db.table_name == "users"


def test_get_user_not_found(monkeypatch):
    fake_db = FakeSupabase(FakeResponse(data=[], error=None))
    monkeypatch.setattr(am, "get_database_connection", lambda: fake_db)

    result = am.getUser("missing@b.com")

    assert result == {"email": "missing@b.com", "result": False}


def test_get_user_db_error(monkeypatch):
    fake_db = FakeSupabase(FakeResponse(data=[], error=FakeError("db failed")))
    monkeypatch.setattr(am, "get_database_connection", lambda: fake_db)

    result = am.getUser("err@b.com")

    assert result["result"] is False
    assert "error" in result


def test_get_user_exception(monkeypatch):
    def _raise():
        raise RuntimeError("connection failed")

    monkeypatch.setattr(am, "get_database_connection", _raise)

    result = am.getUser("x@y.com")

    assert result["result"] is False
    assert "error" in result


def test_validate_user_user_missing(monkeypatch):
    monkeypatch.setattr(am, "getUser", lambda email=None: {"result": False})

    body, status = am.validateUser("x@y.com", "pw")

    assert status == 401
    assert body["error"] == "Invalid credentials"


def test_validate_user_invalid_password(monkeypatch):
    monkeypatch.setattr(
        am,
        "getUser",
        lambda email=None: {
            "result": True,
            "email": "x@y.com",
            "name": "N",
            "lastname": "L",
            "password_hash": "hash",
        },
    )
    monkeypatch.setattr(am, "check_password_hash", lambda _h, _p: False)

    body, status = am.validateUser("x@y.com", "badpw")

    assert status == 401
    assert body["result"] is False
    assert body["error"] == "Invalid credentials"


def test_validate_user_success(monkeypatch):
    monkeypatch.setattr(
        am,
        "getUser",
        lambda email=None: {
            "result": True,
            "email": "x@y.com",
            "name": "N",
            "lastname": "L",
            "password_hash": "hash",
        },
    )
    monkeypatch.setattr(am, "check_password_hash", lambda _h, _p: True)
    monkeypatch.setattr(am, "create_session_token", lambda _u: "token-123")
    monkeypatch.setattr(am, "JWT_EXPIRES_MINUTES", 60)

    body, status = am.validateUser("x@y.com", "goodpw")

    assert status == 200
    assert body["result"] is True
    assert body["access_token"] == "token-123"
    assert body["token_type"] == "Bearer"
    assert body["expires_in"] == 3600


def test_validate_user_exception(monkeypatch):
    monkeypatch.setattr(am, "getUser", lambda email=None: (_ for _ in ()).throw(Exception("fail")))

    body, status = am.validateUser("x@y.com", "pw")

    assert status == 500
    assert "error" in body


def test_delete_user_invalid_credentials_user_not_found(monkeypatch):
    monkeypatch.setattr(am, "getUser", lambda email=None: {"result": False})

    body, status = am.deleteUser("x@y.com", "pw")

    assert status == 401
    assert body["error"] == "Invalid credentials"


def test_delete_user_invalid_credentials_bad_password(monkeypatch):
    monkeypatch.setattr(
        am,
        "getUser",
        lambda email=None: {
            "result": True,
            "email": "x@y.com",
            "name": "N",
            "lastname": "L",
            "password_hash": "hash",
        },
    )
    monkeypatch.setattr(am, "check_password_hash", lambda _h, _p: False)

    body, status = am.deleteUser("x@y.com", "bad")

    assert status == 401
    assert body["error"] == "Invalid credentials"


def test_delete_user_success(monkeypatch):
    monkeypatch.setattr(
        am,
        "getUser",
        lambda email=None: {
            "result": True,
            "email": "x@y.com",
            "name": "N",
            "lastname": "L",
            "password_hash": "hash",
        },
    )
    monkeypatch.setattr(am, "check_password_hash", lambda _h, _p: True)
    fake_db = FakeSupabase(FakeResponse(data=[{"email": "x@y.com"}], error=None))
    monkeypatch.setattr(am, "get_database_connection", lambda: fake_db)

    body, status = am.deleteUser("x@y.com", "ok")

    assert status == 200
    assert body["result"] is True
    assert body["process"] == "Delete User"
    assert fake_db.table_name == "users"


def test_delete_user_db_error(monkeypatch):
    monkeypatch.setattr(
        am,
        "getUser",
        lambda email=None: {
            "result": True,
            "email": "x@y.com",
            "name": "N",
            "lastname": "L",
            "password_hash": "hash",
        },
    )
    monkeypatch.setattr(am, "check_password_hash", lambda _h, _p: True)
    fake_db = FakeSupabase(FakeResponse(data=[], error=FakeError("delete failed")))
    monkeypatch.setattr(am, "get_database_connection", lambda: fake_db)

    body, status = am.deleteUser("x@y.com", "ok")

    assert status == 500
    assert "error" in body


def test_login_resource_post(monkeypatch):
    class DummyParser:
        def add_argument(self, *args, **kwargs):
            return None

        def parse_args(self):
            return {"email": "e@x.com", "password": "pw"}

    monkeypatch.setattr(am.reqparse, "RequestParser", lambda: DummyParser())
    monkeypatch.setattr(am, "validateUser", lambda e, p: ({"result": True, "email": e}, 200))

    body, status = am.LoginResource().post()

    assert status == 200
    assert body["result"] is True
    assert body["email"] == "e@x.com"


def test_login_resource_delete(monkeypatch):
    class DummyParser:
        def add_argument(self, *args, **kwargs):
            return None

        def parse_args(self):
            return {"email": "e@x.com", "password": "pw"}

    monkeypatch.setattr(am.reqparse, "RequestParser", lambda: DummyParser())
    monkeypatch.setattr(am, "deleteUser", lambda e, p: ({"result": True, "email": e}, 200))

    body, status = am.LoginResource().delete()

    assert status == 200
    assert body["result"] is True
    assert body["email"] == "e@x.com"