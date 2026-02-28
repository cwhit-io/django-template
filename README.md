# Django Template

A batteries-included Django project template — production-ready from day one.

**Stack:**

| Layer | Technology |
|---|---|
| Web framework | Django 6 |
| ASGI server | Daphne |
| WebSockets | Django Channels |
| Background tasks | Celery + Redis |
| REST API | Django Ninja (OpenAPI / pydantic v2) |
| CSS | Tailwind CSS v4 |
| Hypermedia | htmx |
| Reactivity | Alpine.js |
| Static files | WhiteNoise |
| Auth | Custom `User(AbstractUser)` |
| Dev reloading | django-browser-reload |

---

## Requirements

- Python 3.11+
- Node.js 18+
- Redis (Celery broker; also used for production channel layer)

---

## Quick start (Makefile)

```bash
git clone <repo-url> my-project
cd my-project
python -m venv .venv && source .venv/bin/activate
make install     # pip install + npm install (copies JS, builds CSS)
cp .env.example .env   # then edit .env and set a real SECRET_KEY
make migrate
make dev         # starts Daphne at http://127.0.0.1:8000
```

In separate terminals:

```bash
make worker      # Celery worker
make tailwind    # Tailwind CSS in watch mode
```

Run tests:

```bash
make test        # pytest
```

---

## Manual setup

### 1. Clone the repository

```bash
git clone <repo-url> my-project
cd my-project
```

### 2. Python virtual environment

```bash
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
```

### 3. Python dependencies

```bash
pip install -r requirements.txt
```

### 4. Environment variables

```bash
cp .env.example .env
# Edit .env — at minimum set a unique SECRET_KEY:
#   python -c "import secrets; print(secrets.token_urlsafe(50))"
```

Key variables in `.env`:

| Variable | Default | Purpose |
|---|---|---|
| `DJANGO_SETTINGS_MODULE` | `config.settings.dev` | Active settings module |
| `SECRET_KEY` | *(required)* | Django secret key |
| `DEBUG` | `True` | Debug mode |
| `DATABASE_URL` | `sqlite:///db.sqlite3` | Database connection |
| `REDIS_URL` | `redis://localhost:6379/0` | Celery broker + prod channels |
| `ALLOWED_HOSTS` | `127.0.0.1,localhost` | Allowed hostnames |

### 5. Node dependencies

Copies Alpine.js and htmx to `static/js/` and builds Tailwind CSS automatically via `postinstall`.

```bash
npm install
```

### 6. Database migrations

```bash
python manage.py migrate
```

### 7. Superuser (optional)

```bash
python manage.py createsuperuser
```

---

## Running the project

### Development server

```bash
daphne config.asgi:application
# or
make dev
```

Visits [http://127.0.0.1:8000](http://127.0.0.1:8000).

### Celery worker

```bash
celery -A config worker -l info
# or
make worker
```

> Requires Redis on `localhost:6379`. Install: `brew install redis` / `sudo apt install redis-server`.

### Tailwind CSS (watch mode)

```bash
npm run tailwind:watch
# or
make tailwind
```

---

## Project structure

```
├── config/
│   ├── settings/
│   │   ├── base.py          # Shared settings (environ, WhiteNoise, Channels, Celery)
│   │   ├── dev.py           # Dev overrides (browser-reload, plain static storage)
│   │   └── prod.py          # Prod overrides (Redis channels, security headers, SMTP)
│   ├── api.py               # Django Ninja API instance + endpoints
│   ├── asgi.py              # Channels ASGI router
│   ├── celery.py            # Celery app
│   ├── urls.py              # Root URL config
│   └── wsgi.py
├── core/                    # Main application
│   ├── migrations/
│   ├── templates/core/
│   │   └── index.html       # htmx + Alpine.js demo page
│   ├── admin.py             # UserAdmin
│   ├── consumers.py         # WebSocket consumer (Channels)
│   ├── models.py            # Custom User model
│   ├── routing.py           # WebSocket URL routes
│   ├── tasks.py             # Celery tasks
│   ├── tests.py             # pytest tests
│   ├── urls.py
│   └── views.py
├── templates/
│   └── base.html            # Base template (Tailwind, htmx, Alpine)
├── static/
│   ├── css/
│   │   ├── input.css        # Tailwind CSS entry point
│   │   └── output.css       # Built CSS (generated, gitignored)
│   └── js/
│       ├── alpine.min.js    # Copied from node_modules (gitignored)
│       └── htmx.min.js      # Copied from node_modules (gitignored)
├── .env                     # Local env vars (gitignored)
├── .env.example             # Env template (committed)
├── conftest.py              # pytest fixtures
├── Makefile                 # Common dev commands
├── package.json
├── pytest.ini
├── requirements.txt
└── tailwind.config.js
```

---

## Settings

Settings are split into three modules under `config/settings/`:

- **`base.py`** — shared across all environments
- **`dev.py`** — development only (browser-reload, plain static storage)
- **`prod.py`** — production (Redis channel layer, all security headers)

The active module is controlled by `DJANGO_SETTINGS_MODULE` in `.env`. Defaults to `config.settings.dev`.

To run in production mode locally:

```bash
DJANGO_SETTINGS_MODULE=config.settings.prod python manage.py check --deploy
```

---

## API

Django Ninja exposes a REST API at `/api/`. Add endpoints in [config/api.py](config/api.py).

- **Swagger UI:** [http://127.0.0.1:8000/api/docs](http://127.0.0.1:8000/api/docs)
- **Example:** `GET /api/hello` → `{"message": "Hello from Django Ninja!"}`

---

## WebSockets

A sample chat consumer is wired up at `ws/chat/<room_name>/`.

```javascript
const ws = new WebSocket("ws://127.0.0.1:8000/ws/chat/myroom/");
ws.onmessage = (e) => console.log(e.data);
ws.send(JSON.stringify({ message: "Hello!" }));
```

Add consumers in `core/consumers.py`, register routes in `core/routing.py`.

---

## Celery tasks

```python
# core/tasks.py
from celery import shared_task

@shared_task
def my_task(name):
    return f"Hello, {name}!"
```

```python
# from a view
from core.tasks import my_task
my_task.delay("World")
```

---

## Custom User model

`core.User` extends `AbstractUser`. Always use `AUTH_USER_MODEL` / `get_user_model()` for references:

```python
from django.contrib.auth import get_user_model
User = get_user_model()
```

---

## Static files

In development, Django serves static files directly. In production, WhiteNoise serves them via `CompressedManifestStaticFilesStorage`. Run `collectstatic` before deploying:

```bash
make collectstatic
# or
python manage.py collectstatic --no-input
```

---

## Testing

```bash
make test
# or
pytest
```

Tests live in `core/tests.py`. Fixtures are in `conftest.py`. Settings default to `config.settings.dev` (see `pytest.ini`).

---

## Production checklist

- [ ] Set a strong `SECRET_KEY` in `.env`
- [ ] Set `DEBUG=False`
- [ ] Set `DJANGO_SETTINGS_MODULE=config.settings.prod`
- [ ] Set `DATABASE_URL` to a production database
- [ ] Set `REDIS_URL` to your Redis instance
- [ ] Set `ALLOWED_HOSTS` to your domain(s)
- [ ] Set `EMAIL_*` variables for transactional email
- [ ] Run `python manage.py collectstatic`
- [ ] Run `python manage.py check --deploy`
