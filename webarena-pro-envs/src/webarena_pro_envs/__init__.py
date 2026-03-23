WEBSITES_IMAGES = {
    "nextcloud": "webarenapro/nextcloud:latest",
    "flight-search": "webarenapro/flight-search:latest",
    "jobportal": "webarenapro/jobportal:latest",
    "dealflow": "webarenapro/dealflow:latest",
}

WEBSITES_CONTAINER_PORTS = {
    "nextcloud": 80,
    "flight-search": 80,
    "jobportal": 8000,
    "dealflow": 4520,
}

WEBSITES_HOST_PORTS = {
    "nextcloud": 3210,
    "flight-search": 2210,
    "jobportal": 4510,
    "dealflow": 4520,
}

WEBSITES_FIXED_URLS = {
    name: f"http://localhost:{host_port}"
    for name, host_port in WEBSITES_HOST_PORTS.items()
}
