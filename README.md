# sinanoki
「科の木（しなのき）」は、Wiki風編集インターフェースを備えた静的サイトジェネレータです。Rubyで書かれています。

## 使い方
### 依存ライブラリのインストール
まだ Bundler 用の設定ファイルを作っていないので、以下のGemを何らかの方法でインストールしてください。

- sinatra
- haml
- redcarpet
- rouge
- git

### 初期化
最初に一度だけ行ってください。

```sh
$ cp conf.yaml.default conf.yaml
$ ruby init_repo.rb
```

`srcrepo` ディレクトリ以下に原稿ファイル用のレポジトリが作成されます。

### 起動
```sh
$ ruby sinanoki.rb
```

で起動します。

<http://localhost:4567> にアクセスしてください。

上の「編集」ボタンを押すとそのページを編集できます。

編集ページで「更新」を押すと、 `srcrepo` のGitレポジトリにMarkdownのファイルが生成され、自動でコミットされます。

### 静的ファイルの生成
公開サーバーで公開するための静的なファイルが、コミットと同時に `dst` ディレクトリに生成されます。この際、生成（更新）されるファイルは今更新したファイルだけです。

サイト全体を再生成したいときは、 `http://localhost:4567/generate_all` にアクセスしてください。

cssなどはコピーされないので、 `public` ディレクトリ以下のディレクトリを手動でコピーしてください（今後自動化予定）。

### 静的ファイルのサーバーへのコピー（いわゆるデプロイ）
`post-generation.rb` という名前でRubyスクリプトを置いておくと、「静的ファイルのの生成」の後にそのスクリプトが実行されます。

ここでrsyncなどを行うようにすると、サイトデータの更新後自動でサーバーにコピーさせることができます。

## Markdown記法について
基本的には [Redcarpet](https://github.com/vmg/redcarpet) の対応している記法に従います。

以下の拡張があります。

- `[[pagename]]` で、サイトの中の `pagename` という名前のページにリンクするWiki風記法

