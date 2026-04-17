# warren

`warren` is a small tool for previewing MoonBit web projects locally with live reload.

## Install

Install with Moon:

```sh
moon install moonbit-community/warren
```

This gives you the `warren` command.

## Use

Run inside your MoonBit project:

```sh
warren dev
```

Then open:

```txt
http://127.0.0.1:3070
```

Your project should have a runnable main package.

## `public/`

`public/` is optional.

If you want to customize the page, create `public/` in your module root and add:

- `public/index.html`
- `public/styles.css`

Common usage:

- Add `public/index.html` if you want to control the page structure
- Add `public/styles.css` if you want custom styles
- Both files are optional

## Status

- [x] `warren dev`
- [ ] `moon.work` support
- [ ] `warren build`
- [ ] AI debugging utils
