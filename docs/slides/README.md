# InnerSource Program Office (ISPO) Working Group Presentation Slides

We use [Marp](https://marp.app/) to create our slides.

Why? Because it's easy to use, it's free, facilitates efficient collaboration, and it's open source.

## How to create slides

1. Install Marp CLI

    ```bash
    npm install -g @marp-team/marp-cli
    ```

2. Create a new slide deck

    ```bash
    touch deck.md
    ```

3. Edit the slide deck
4. Export the slide deck to PDF

    ```bash
    marp deck.md --pdf
    ```

5. Open the PDF file in your PDF viewer
6. Commit the slide deck

```bash
git add deck.md deck.html deck.pdf
git commit -m "Add slide deck"
```

Alternatively, install the [Marp for VS Code](https://marketplace.visualstudio.com/items?itemName=marp-team.marp-vscode) extension and use the "Marp: Export slide deck" command to export the slide deck to HTML and PDF.
