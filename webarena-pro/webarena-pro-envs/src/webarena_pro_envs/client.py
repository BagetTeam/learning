"""Client for using WebArena Pro environments API to manage containers and interact with them."""

import httpx
from pydantic import BaseModel

class ContainerInfo(BaseModel):
    name: str
    status: str
    health: str

class WebArenaProClient:
    def __init__(self, base_url: str):
        self.base_url = base_url
        self.client = httpx.Client(base_url=self.base_url)

    def list_containers(self):
        response = self.client.get("/containers")
        response.raise_for_status()
        return [ContainerInfo(**container) for container in response.json()]

    def start_container(self, name: str, image: str):
        response = self.client.post(f"/containers/{name}/start", params={"image": image})
        response.raise_for_status()
        return response.json()

    def reset_container(self, name: str, image: str):
        response = self.client.post(f"/containers/{name}/reset", params={"image": image})
        response.raise_for_status()
        return response.json()

    def stop_container(self, name: str):
        response = self.client.post(f"/containers/{name}/stop")
        response.raise_for_status()
        return response.json()

    def health_check(self, name: str):
        response = self.client.post(f"/containers/{name}/health")
        response.raise_for_status()
        return response.json()
    
    def get_status(self, name: str):
        response = self.client.get(f"/containers/{name}/status")
        response.raise_for_status()
        return response.json()
