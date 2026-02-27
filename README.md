# WebArena-Pro

Welcome to WebArena-Pro's project repository!

## Contributing to WebArena Pro

Since all contributors currently have **read-only access** to the main repository, all code contributions must follow the standard **Fork and Pull Request** workflow.

Follow these essential steps to set up your environment and submit your code:

**1. Fork & Clone** Fork the main repository to your personal GitHub account using the GitHub UI, then clone your personal fork to your local machine:

```bash
git clone https://github.com/YOUR-USERNAME/webarena-pro.git
cd webarena-pro

```

**2. Add Upstream** Link the main McGill-NLP repository so you can easily pull future updates and keep your local environment synced:

```bash
git remote add upstream https://github.com/McGill-NLP/webarena-pro.git

```

**3. Create a Branch** Never commit directly to your `main` branch. Always create a new feature branch for your environment or bug fix:

```bash
git checkout -b feature/your-feature-name

```

**4. Push & Submit PR** Commit your changes locally, push them to your fork, and then open a Pull Request on the main McGill-NLP repository for the Integration team to review:

```bash
git push origin feature/your-feature-name

```

**5. Stay Synced** Regularly fetch and merge changes from the main repository's `main` branch before starting any new work to avoid merge conflicts:

```bash
git fetch upstream
git merge upstream/main

```

## Pushing Images to GitHub Registry

Once your Docker image is built and tested locally, push it to the McGill-NLP GitHub registry so that it becomes available to all members of the team. Follow these steps:

1 - Create a classic GitHub Access Token with permissions: `repo` and `packages`. Then export the token with the following command:
```sh
export CR_PAT=<YOUR_TOKEN> # generally starts with ghp_...
```
2 - Authenticate to the GitHub registry with your username and the token you just created:
```sh
 echo $CR_PAT | docker login ghcr.io -u USERNAME --password-stdin
``` 
3 - Tag your image so that it will be pushed to the correct registry:
```sh
docker tag <IMAGE_ID> ghcr.io/mcgill-nlp/<IMAGE_NAME>:<VERSION>

# Example: I have a local image hello-world:latest with ID 1b44b5a3e06a
docker tag 1b44b5a3e06a ghcr.io/mcgill-nlp/hello-world:latest
```
4 - Push the tagged image to the registry:
```sh
docker push ghcr.io/mcgill-nlp/<IMAGE_NAME>:<VERSION>

# Example
docker push ghcr.io/mcgill-nlp/hello-world:latest
```

If all steps are completed correctly, you should see your image in the Packages section on McGill-NLP organization page.

<img width="1017" height="375" alt="image" src="https://github.com/user-attachments/assets/b70fb73a-d0cf-4e51-b7e4-53e9cb51a964" />


To use an image published to the registry, run (the exact command is given when you click on the desired package):

```sh
docker pull ghcr.io/mcgill-nlp/<IMAGE_NAME>:<VERSION>

# Example
docker pull ghcr.io/mcgill-nlp/hello-world:latest
```

(Optional) Before building the image locally, add the following command to your Dockerfile. This will link the image to the `webarena-pro` repository.

```sh
LABEL org.opencontainers.image.source https://github.com/McGill-NLP/webarena-pro

# Run docker build
docker build ...

# Follow previous steps to push the image to the registry
...
```

## 🌳 Recommended Workflow: Git Worktrees

If you frequently find yourself switching between branches, stashing half-finished work, or needing to test the `main` branch while in the middle of a complex feature, we highly recommend using **Git Worktrees**. 

A Git worktree allows you to check out multiple branches of this repository into entirely separate directories on your local machine. This means you can:
- **Multitask effortlessly:** Keep your local dev server running on one branch while you quickly review a PR or fix a bug in another folder.
- **Avoid context switching:** Stop relying on `git stash` and avoid the risk of losing uncommitted work when pulling updates.
- **Compare side-by-side:** Open two different branches in separate editor windows to easily compare code or run them concurrently.

**Using Worktrees in VS Code:**
Visual Studio Code has excellent built-in support for worktrees. You can create and manage them directly from the UI:
1. Go to the **Source Control** view.
2. Expand the **Source Control Repositories** section.
3. Click the **More Actions (...)** menu > **Worktrees** > **Create Worktree**.

For a full guide on how to create, open, and manage worktrees, check out the official documentation:
👉 [Working with Git Worktrees in VS Code](https://code.visualstudio.com/docs/sourcecontrol/branches-worktrees#_working-with-git-worktrees)
