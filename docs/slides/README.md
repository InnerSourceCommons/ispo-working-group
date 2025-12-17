# InnerSource Program Office (ISPO) Working Group Presentation Slides

We use [Marp](https://marp.app/) to create our slides.

> **Note:** Slides (PDF, HTML, PPTX) are automatically generated via GitHub
> Actions when changes are pushed to `main`. You can also generate them locally
> using the script below.

## How to create slides

1. Create a new slide deck in a subdirectory:

    ```bash
    mkdir docs/slides/my-presentation
    touch docs/slides/my-presentation/my-presentation.md
    ```

2. Edit the slide deck with this header:

    ```markdown
    ---
    marp: true
    theme: ispowg
    themeSet: ../themes
    ---
    ```

3. Generate all slides:

    ```bash
    ./docs/slides/scripts/generate-slides.sh
    ```

    Generates PDF, HTML, and PPTX for all slide decks. Requires `marp-cli`
    (`npm install -g @marp-team/marp-cli`) or Docker.

4. Preview in VS Code using the [Marp extension](https://marketplace.visualstudio.com/items?itemName=marp-team.marp-vscode).
