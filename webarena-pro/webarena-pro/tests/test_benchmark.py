import json

from webarena_pro.benchmark.benchmark import WebArenaProBenchmark


def test_benchmark_loads_tasks_with_unique_container_names(tmp_path, monkeypatch):
    monkeypatch.setattr(
        "webarena_pro.task.DEPLOYED_WEBSITE_URLS",
        {"nextcloud": "http://localhost:3210"},
    )

    test_set = tmp_path / "test.raw.json"
    test_set.write_text(
        json.dumps(
            [
                {
                    "task_id": "test_task_1",
                    "intent": "Task one",
                    "website": "nextcloud",
                    "evaluation": "/tmp/eval1",
                },
                {
                    "task_id": "test_task_2",
                    "intent": "Task two",
                    "website": "nextcloud",
                    "evaluation": "/tmp/eval2",
                },
            ]
        ),
        encoding="utf-8",
    )

    benchmark = WebArenaProBenchmark(test_set_path=str(test_set))

    assert len(benchmark.env_args_list) == 2
    container_names = {
        env_args.task_config.container_name for env_args in benchmark.env_args_list
    }
    assert len(container_names) == 2
    assert benchmark.env_args_list[0].task_name == "webarena-pro.test_task_1"
    assert benchmark.env_args_list[1].task_name == "webarena-pro.test_task_2"
    assert all(env_args.max_steps == 30 for env_args in benchmark.env_args_list)


def test_benchmark_adds_dependencies_for_same_website(tmp_path, monkeypatch):
    monkeypatch.setattr(
        "webarena_pro.task.DEPLOYED_WEBSITE_URLS",
        {
            "nextcloud": "http://localhost:3210",
            "gitlab": "http://localhost:9999",
        },
    )

    test_set = tmp_path / "test.raw.json"
    test_set.write_text(
        json.dumps(
            [
                {
                    "task_id": "task_a1",
                    "intent": "Task A1",
                    "website": "nextcloud",
                    "evaluation": "/tmp/eval1",
                },
                {
                    "task_id": "task_b1",
                    "intent": "Task B1",
                    "website": "gitlab",
                    "evaluation": "/tmp/eval2",
                },
                {
                    "task_id": "task_a2",
                    "intent": "Task A2",
                    "website": "nextcloud",
                    "evaluation": "/tmp/eval3",
                },
            ]
        ),
        encoding="utf-8",
    )

    benchmark = WebArenaProBenchmark(test_set_path=str(test_set))
    dependencies = benchmark.dependency_graph_over_tasks()

    assert dependencies["webarena-pro.task_a1"] == []
    assert dependencies["webarena-pro.task_b1"] == []
    assert dependencies["webarena-pro.task_a2"] == ["webarena-pro.task_a1"]
