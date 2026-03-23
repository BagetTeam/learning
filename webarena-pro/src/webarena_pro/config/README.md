# Task Configuration Guide

Use `test.raw.json` as a JSON array of task objects.

## Template

```json
{
	"sites": [
		"nextcloud"
	],
	"task_id": 0,
	"require_login": true,
	"storage_state": "./.auth/nextcloud_state.json",
	"start_url": "__NEXTCLOUD__",
	"geolocation": null,
	"intent_template": "",
	"instantiation_dict": {},
	"intent": "Delete all the individual contents of each folder then restore them using the trash folder and add them back to the folders they originally came from.",
	"require_reset": false,
	"eval": {
		"eval_types": [
			"llm_judge_with_hint"
		],
		"reference_answers": {
			"exact_match": ""
		},
		"reference_url": "",
		"program_html": [],
		"string_note": "",
		"reference_answer_raw_annotation": ""
	},
	"intent_template_id": null
}
```

## Field Instructions

- `sites`: list of target site IDs (for example `"nextcloud"`, `"notion"`, `"flight-search"`).
- `task_id`: integer identifier unique inside the file.
- `require_login`: set to `true` if the task needs an authenticated session.
- `storage_state`: path to Playwright storage state used when `require_login` is `true`.
- `start_url`: starting URL or environment placeholder token (for example `"__NEXTCLOUD__"`).
- `geolocation`: use `null` unless the task explicitly depends on location.
- `intent_template`: optional parameterized prompt; keep `""` if not templated.
- `instantiation_dict`: values used to instantiate `intent_template`; keep `{}` if unused.
- `intent`: the concrete natural-language instruction the agent must solve.
- `require_reset`: set to `true` only if the environment must be reset after the task.
- `eval.eval_types`: evaluation method list (for example `"string_match"`, `"url_match"`, `"program_html"`).
- `eval.reference_answers`: expected answer(s) for `string_match`.
- `eval.reference_url`: expected URL or URL pattern for `url_match`.
- `eval.program_html`: HTML assertions for `program_html` checks.
- `eval.string_note`: optional note for evaluator edge cases.
- `eval.reference_answer_raw_annotation`: optional annotation metadata.
- `intent_template_id`: template version/id; keep aligned with your template tracking; keep "null" if not templated.

## Quick Checklist

- Keep each `task_id` unique.
- Ensure `sites`, `start_url`, and `storage_state` match the same website.
- Add only evaluation fields required by your `eval_types`.
- Validate JSON format (no trailing commas, double quotes only).
