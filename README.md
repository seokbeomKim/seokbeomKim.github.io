# Blog

This site uses Hugo and accepts both Markdown (`.md`) and Org (`.org`) posts
under `content/posts/`. Org files render directly; exporting to Markdown or
running Emacs is not required.

## Create an Org post

```sh
hugo new posts/my-post.org
```

The Org archetype creates a draft with a title, date, tags, and table of contents.
Set `#+DRAFT: false` when the post is ready to publish.

```org
#+TITLE: My post
#+DATE: 2026-10-11T12:00:00+09:00
#+DRAFT: false
#+TAGS[]: emacs linux
#+TOC: true

* Overview

Use *bold*, /italic/, ~inline code~, and [[https://example.com][links]].

** Details

- First item
- Second item

| Name | Value |
|------+-------|
| Org  | yes   |

#+begin_src sh
echo "Hello from Org"
#+end_src

#+begin_example
Hello from Org
#+end_example
```

Use `#+TAGS[]: emacs linux` for multiple tags or `#+TAGS: emacs` for one tag.
YAML/TOML front matter also works in `.org` files. `#+HUGO_*` keywords belong
to the ox-hugo export workflow; use Hugo's native front matter keywords for
direct rendering. See [Hugo's Org front matter documentation](https://gohugo.io/content-management/front-matter/#emacs-org-mode).

Source blocks and example blocks have the same monochrome copy and wrapping
buttons as Markdown code blocks. Line wrapping starts disabled.

To make an Org source block start collapsed, add the site-specific `:collapse yes`
option after the language:

```org
#+begin_src c :collapse yes :title "Example program"
int main(void) {
    return 0;
}
#+end_src
```

Click the language header, or focus it and press Enter or Space, to expand or
collapse the code. Expanded blocks retain the copy and wrapping controls.
The optional `:title "Example program"` adds a subtitle, displayed as
`C: Example program`. Use double quotes for titles containing spaces.
Omit the option or use `:collapse no` to leave the block expanded. The native
disclosure works without JavaScript; the copy and wrapping buttons require it.

## Sidenotes and footnotes

In Org, use a `sidenote:` link to select the exact phrase that opens a sidenote:

```org
[[sidenote:cc-mode][C and C++ editing with cc-mode]] is useful.

[fn:sn-cc-mode] A C-family language editing package for Emacs.
```

The link target `cc-mode` selects the definition `[fn:sn-cc-mode]`; the link
description is the entire clickable phrase. Multiple links can share a
definition while displaying different phrases. The phrase has a dashed
underline, without a footnote number. Definitions may contain Org formatting
and links. Place each definition at the start of a line, as in the example.

Wide screens display the explanation in the margin; narrow screens expand or
collapse it when the phrase is clicked. These links are converted in the browser
and require JavaScript.

The previous footnote-reference syntax is also supported:

```org
cc-mode[fn:sn-cc-mode] and tree-sitter[fn:sn-tree-sitter] are tools.

[fn:sn-cc-mode] C and C++ editing support in Emacs.
[fn:sn-tree-sitter] A parser with *bold text*, ~inline code~, and [[https://example.com][links]].
```

Named inline definitions work too:

```org
A short explanation[fn:sn-explanation: This appears as a sidenote.].
```

The part after `sn-` is the clickable term. Write the reference immediately
after that term: `cc-mode[fn:sn-cc-mode]` displays `cc-mode` once, with a dashed
underline and no footnote number. Inline code or emphasis on the term is
preserved. If the matching term is absent, the term is inserted at the reference.
Wide screens show the notes in the article margin without overlap; narrow
screens let readers click the term to expand or collapse its note.
Repeated references each show the same note.
The converted definitions are removed from the bottom of the page. Footnotes
without the `sn-` prefix stay at the bottom.

Conversion runs in the browser. With JavaScript disabled, these notes remain
ordinary footnotes with working links and definitions.

Use the `sidenote` shortcode in Markdown or Org to attach an explanation to a term:

```text
{{< sidenote "cc-mode" >}}Explanation of cc-mode.{{< /sidenote >}}
```

The first argument is the term shown in the body. The content between the
shortcodes is the explanation; use plain text or HTML for formatting. Wide
screens show the explanation beside the article. On narrow screens, click
the term to expand or collapse it.

For a footnote at the end of an Org document, use:

```org
A sentence with a footnote.[fn:note]

[fn:note] Footnote explanation.
```

The rendering test at `/posts/org-rendering-test/` includes both types of notes.

## Preview

```sh
hugo server --buildDrafts
```

Build with `hugo`. The deployment script also commits and pushes repositories;
use the build command for local verification.
