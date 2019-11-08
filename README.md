# sinanoki
「科の木（しなのき）」は、Wiki風編集インターフェースを備えた静的サイトジェネレータです。Rubyで書かれています。

## 使い方
### 依存ライブラリのインストール
[Bundler](https://bundler.io/) が必要です。あらかじめインストールしておいてください。

Bundler のインストールが済んでいる場合、

```sh
$ bundle install --path vendor/bundle
```

で依存ライブラリをインストールできます。

### 初期化
最初に一度だけ行ってください。

```sh
$ cp conf.yaml.default conf.yaml # 設定ファイルの作成
$ ruby init_repo.rb # データを保存するためのGitリポジトリを作成
$ ruby copy_static_files.rb # cssやjs等のファイルを静的サイトの出力ディレクトリにコピー
```

`srcrepo` ディレクトリ以下に原稿ファイル用のリポジトリが作成されます。

### 起動
```sh
$ bundle exec ruby sinanoki.rb
```

で起動します。

<http://localhost:4567> にアクセスしてください。

上の「編集」ボタンを押すとそのページを編集できます。

編集ページで「更新」を押すと、 `srcrepo` のGitリポジトリにMarkdownのファイルが生成され、自動でコミットされます。

### 静的ファイルの生成
公開サーバーで公開するための静的なファイルが、コミットと同時に `dst` ディレクトリに生成されます。この際、生成（更新）されるファイルは今更新したファイルだけです。

サイト全体を再生成したいときは、 `http://localhost:4567/generate_all` にアクセスしてください。
特に新しいページを作ったときは、これを行わないとリンク元のページに `<未>` が表示されたままになります。

### 静的ファイルのサーバーへのコピー（いわゆるデプロイ）
`post-generation.rb` という名前でRubyスクリプトを置いておくと、「静的ファイルの生成」の後にそのスクリプトが実行されます。

ここでrsyncなどを行うようにすると、サイトデータの更新後自動でサーバーにコピーさせることができます。

`post-generation.rb` の例：

```ruby
#!/usr/bin/env ruby
system("rsync -av dst/ remoteserver:public_html/shoko/")
```

## Markdown記法について
基本的には [Redcarpet](https://github.com/vmg/redcarpet) の対応している記法に従います。

以下の拡張があります。

- `[[pagename]]` で、サイトの中の `pagename` という名前のページにリンクするWiki風記法
- `$\sin x$`, `$$\cos x$$` という記法でのTeX数式対応（[KaTeX](https://katex.org/)を利用）

## リポジトリのフック
（これはsinanoki自体の機能ではありませんが）Gitリポジトリにpost-commitフックを仕込むことで、コミット時（＝記事更新時）に何らかの動作をさせることができます。

たとえば、 `srcrepo/.git/hooks/post-commit` に

```sh
#!/bin/sh
git push origin master
```

と書くと、記事リポジトリをリモートリポジトリにバックアップできます。
