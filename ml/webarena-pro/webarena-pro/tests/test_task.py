import sys
import types

from webarena_pro.benchmark.task import DEPLOYED_WEBSITE_URLS, WebArenaProTask, WebArenaProTaskConfig


class DummyPage:
	def __init__(self) -> None:
		self.last_url = None

	def goto(self, url: str) -> None:
		self.last_url = url


def test_task_setup_uses_hardcoded_deployed_url(monkeypatch):
	config = WebArenaProTaskConfig(
		task_id="task-1",
		intent="Find document",
		website="nextcloud",
		evaluation=None,
		container_name="webarena-pro-task-1-0",
		start_url=DEPLOYED_WEBSITE_URLS["nextcloud"],
		startup_wait_seconds=1.0,
	)
	observed_sleeps = []
	monkeypatch.setattr("webarena_pro.benchmark.task.time.sleep", lambda seconds: observed_sleeps.append(seconds))

	task = WebArenaProTask(seed=0, config=config)
	page = DummyPage()
	goal, info = task.setup(page)

	assert goal == "Find document"
	assert info["task_id"] == "task-1"
	assert info["website"] == "nextcloud"
	assert page.last_url == DEPLOYED_WEBSITE_URLS["nextcloud"]
	assert info["start_url"] == DEPLOYED_WEBSITE_URLS["nextcloud"]
	assert observed_sleeps == [config.startup_wait_seconds]


def test_task_teardown_is_noop():
	config = WebArenaProTaskConfig(
		task_id="task-1",
		intent="Find document",
		website="nextcloud",
		evaluation=None,
		container_name="webarena-pro-task-1-0",
		start_url=DEPLOYED_WEBSITE_URLS["nextcloud"],
	)

	task = WebArenaProTask(seed=0, config=config)

	assert task.teardown() is None


def test_task_config_from_raw_task_uses_hardcoded_start_url():

	raw_task = {
		"task_id": "task-3",
		"intent": "Open app",
		"website": "nextcloud",
		"eval": {
			"eval_types": ["string_match"],
			"reference_answers": {"exact_match": ""},
		},
	}

	config = WebArenaProTaskConfig.from_raw_task(
		raw_task=raw_task,
		container_name="webarena-pro-task-3-0",
	)

	assert config.start_url == DEPLOYED_WEBSITE_URLS["nextcloud"]


def test_task_config_from_raw_task_supports_wait_override(monkeypatch):
	raw_task = {
		"task_id": "task-4",
		"intent": "Open app",
		"website": "nextcloud",
		"eval": {
			"eval_types": ["string_match"],
			"reference_answers": {"exact_match": ""},
		},
		"startup_wait_seconds": 5,
	}

	config = WebArenaProTaskConfig.from_raw_task(
		raw_task=raw_task,
		container_name="webarena-pro-task-4-0",
	)

	assert config.startup_wait_seconds == 5.0


def test_task_config_from_raw_task_uses_fixed_login_url(monkeypatch):
	raw_task = {
		"task_id": "task-5",
		"intent": "Login first",
		"website": "nextcloud",
		"eval": {
			"eval_types": ["string_match"],
			"reference_answers": {"exact_match": ""},
		},
		"require_login": True,
		"login_page": "http://localhost:9999/login",
	}

	config = WebArenaProTaskConfig.from_raw_task(
		raw_task=raw_task,
		container_name="webarena-pro-task-5-0",
	)

	assert config.require_login is True
	assert config.login_page == "http://localhost:3210/login"


def test_task_setup_calls_ui_login_when_required(monkeypatch):
	config = WebArenaProTaskConfig(
		task_id="task-6",
		intent="Do task",
		website="nextcloud",
		evaluation=None,
		container_name="webarena-pro-task-6-0",
		start_url=DEPLOYED_WEBSITE_URLS["nextcloud"],
		require_login=True,
		startup_wait_seconds=1.0,
	)
	observed_sleeps = []
	login_calls = []
	monkeypatch.setattr("webarena_pro.benchmark.task.time.sleep", lambda seconds: observed_sleeps.append(seconds))
	monkeypatch.setattr(
		"webarena_pro.benchmark.task.WebArenaProTask._ui_login",
		lambda self, page, target_url: login_calls.append(target_url),
	)

	task = WebArenaProTask(seed=0, config=config)
	page = DummyPage()
	goal, info = task.setup(page)

	assert goal == "Do task"
	assert info["start_url"] == DEPLOYED_WEBSITE_URLS["nextcloud"]
	assert observed_sleeps == [config.startup_wait_seconds]
	assert login_calls == [DEPLOYED_WEBSITE_URLS["nextcloud"]]
	assert page.last_url == DEPLOYED_WEBSITE_URLS["nextcloud"]


def test_task_validate_uses_eval_router(monkeypatch):
	captured = {}

	def fake_router(_config_file):
		def fake_evaluator(trajectory, config_file, page, client, last_step_output):
			captured["trajectory"] = trajectory
			captured["config_file"] = config_file
			captured["last_step_output"] = last_step_output
			return 1.0
		return fake_evaluator

	fake_eval_module = types.SimpleNamespace(evaluator_router_websynth=fake_router)
	monkeypatch.setitem(sys.modules, "webarena_pro.eval.evaluators", fake_eval_module)

	config = WebArenaProTaskConfig(
		task_id="task-7",
		intent="Do task",
		website="nextcloud",
		container_name="webarena-pro-task-7-0",
		start_url=DEPLOYED_WEBSITE_URLS["nextcloud"],
		evaluation={
			"eval_types": ["llm_judge_with_hint"],
			"reference_answers": {"hint": "The task is done when the file is removed."},
		},
		raw_task={
			"task_id": "task-7",
			"intent": "Do task",
			"eval": {
				"eval_types": ["llm_judge_with_hint"],
				"reference_answers": {"hint": "The task is done when the file is removed."},
			},
			"persona": {
				"name": "Test User",
				"skills": [],
				"interests": [],
				"description": "",
			},
		},
	)

	task = WebArenaProTask(seed=0, config=config)
	score, done, _, info = task.validate(
		page=DummyPage(),
		chat_messages=[{"role": "assistant", "message": "Final answer"}],
		last_step_output={"episode_info": []},
	)

	assert score == 1.0
	assert done is True
	assert info["task_id"] == "task-7"
	assert captured["trajectory"] == [{"answer": "Final answer"}]


def test_task_validate_returns_zero_without_eval_config():
	config = WebArenaProTaskConfig(
		task_id="task-8",
		intent="Do task",
		website="nextcloud",
		container_name="webarena-pro-task-8-0",
		start_url=DEPLOYED_WEBSITE_URLS["nextcloud"],
		evaluation=None,
	)

	task = WebArenaProTask(seed=0, config=config)
	score, done, _, info = task.validate(page=DummyPage(), chat_messages=[])

	assert score == 0.0
	assert done is False
	assert info["score"] == 0.0
