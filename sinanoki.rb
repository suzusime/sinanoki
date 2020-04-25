require 'sinatra'
require 'haml'
require 'fileutils'
require 'redcarpet'
require 'rouge'
require 'rouge/plugins/redcarpet'
require 'cgi'
require 'git'

# 設定
sinanoki_config = File.open('conf.yaml', 'r') do |f| YAML.load(f) end
sinanoki_config.freeze
SourceRepo = sinanoki_config["source_repogitory"].freeze
PublicDest = sinanoki_config["public_dest"].freeze
WIKI_ROOT = sinanoki_config["wiki_root"].freeze
PUBLIC_ROOT = sinanoki_config["public_root"].freeze
SITE_NAME = sinanoki_config["site_name"].freeze

FileUtils.mkdir_p(PublicDest)

# Markdownのカスタムレンダラ
# ここをいじることで新たな記法を追加できる
class CustomRender < Redcarpet::Render::HTML
  include Rouge::Plugins::Redcarpet
  def initialize(*args)
    super
    @root = WIKI_ROOT
  end

  def set_wiki_mode
    @root = WIKI_ROOT
  end

  def set_public_mode
    @root = PUBLIC_ROOT
  end

  def preprocess(full_document)
    # [[pagename]] で pagename にリンクする
    full_document.gsub(/\[\[(.+)\]\]/) {
      page=$1
      if File.exists?("#{SourceRepo}/src/#{page}.md") then
        "[#{page}](#{@root}/#{page}.html)"
      else
        "[*#{page} <未>*](#{@root}/#{page}.html)"
      end
    }
  end
end

# 諸々のグローバルなオブジェクトの用意
rouge_css = Rouge::Themes::IgorPro.render(:scope => '.highlight')
renderer = CustomRender.new(hard_wrap: true)
markdown = Redcarpet::Markdown.new(renderer, fenced_code_blocks: true, strikethrough: true, underline: true, footnotes: true, no_intra_emphasis: true, tables: true)

# ここからルーティング
get WIKI_ROOT+'/' do
  redirect to("/index.html")
end

get  WIKI_ROOT+'/edit' do
  @pagename = params[:pagename]
  @pagetitle = "編集: #{@pagename} - #{SITE_NAME}"
  @rouge_css = rouge_css
  @root = WIKI_ROOT
  if File.exist?("#{SourceRepo}/src/#{@pagename}.md") then
    @source_exsists = true
    File.open("#{SourceRepo}/src/#{@pagename}.md", "r") do |f|
      @content = f.read
    end
  end
  haml :edit
end

get  WIKI_ROOT+'/*.html' do
  @pagename = params[:splat][0]
  @pagetitle = "#{@pagename} - #{SITE_NAME}"
  # puts "pagename は #{@pagename} です"
  @rouge_css = rouge_css
  @root = WIKI_ROOT
  if File.exist?("#{SourceRepo}/src/#{@pagename}.md") then
    @source_exsists = true
    File.open("#{SourceRepo}/src/#{@pagename}.md", "r") do |f|
      @content = markdown.render(f.read)
    end
  end
  puts @content.inspect
  haml :read
end

post  WIKI_ROOT+'/preview' do
  @root = WIKI_ROOT
  @preview_mode = true
  @rouge_css = rouge_css
  @pagename = params[:pagename]
  @pagetitle = "プレビュー: #{@pagename} - #{SITE_NAME}"
  @content = params[:content]
  @commitmessage = params[:commitmessage]
  @preview_content = markdown.render(@content)
  haml :edit
end

post  WIKI_ROOT+'/update' do
  @root = WIKI_ROOT
  pagename = params[:pagename]
  @pagetitle = "#{pagename} - #{SITE_NAME}"
  newcontent = params[:content]
  commitmessage = params[:commitmessage]
  if commitmessage == '' then
    commitmessage = "<empty #{Time.now}>"
  end
  filename = "#{SourceRepo}/src/#{pagename}.md"
  newcontent.gsub!(/\R/, "\n") #改行コードをLFに統一
  if pagename =~ /\// then
    FileUtils.mkdir_p File::dirname(filename)
  end
  File.open(filename, "w") do |f|
    f.puts(newcontent)
  end

  # Gitリポジトリにコミット
  g = Git.open(SourceRepo)
  g.add
  g.commit(commitmessage)

  # 静的サイト用HTMLを生成
  @rouge_css = rouge_css
  @root = PUBLIC_ROOT
  @last_modified = g.log.path("src/#{pagename}.md").first.committer_date
  renderer.set_public_mode
  File.open("#{SourceRepo}/src/#{pagename}.md", "r") do |f|
    @content = markdown.render(f.read)
  end
  htmlpath = "#{PublicDest}/#{pagename}.html"
  if pagename =~ /\// then
    FileUtils.mkdir_p File::dirname(htmlpath)
  end
  File.open(htmlpath, "w") do |f|
    f.write(haml :public)
  end

  #設定を戻す
  @root = WIKI_ROOT
  renderer.set_wiki_mode
  
  # フック
  if File.exist?('post-generation.rb') then
    system('ruby post-generation.rb')
  end

  # 更新終了
  redirect to(CGI.escape("#{WIKI_ROOT}/#{pagename}.html"))
end

# すべてのMarkdownに対してhtmlを生成
get WIKI_ROOT+'/generate_all' do
  # 全ページのリストを作成
  filelist = []
  FileUtils.chdir("#{SourceRepo}/src") { |dir|
    Dir.glob("**/*").each do |f|
      if f =~ /(.+)\.md/ then
        filelist.push $1
      end
    end
  }

  # 静的サイト用HTMLを生成
  @rouge_css = rouge_css
  @root = PUBLIC_ROOT
  g = Git.open(SourceRepo)
  renderer.set_public_mode
  filelist.each do |pagename|
    @pagetitle = "#{pagename} - #{SITE_NAME}"
    @last_modified = g.log.path("src/#{pagename}.md").first.committer_date
    File.open("#{SourceRepo}/src/#{pagename}.md", "r") do |f|
      @content = markdown.render(f.read)
    end
    htmlpath = "#{PublicDest}/#{pagename}.html"
    if pagename =~ /\// then
      FileUtils.mkdir_p File::dirname(htmlpath)
    end
    File.open(htmlpath, "w") do |f|
      f.write(haml :public)
    end
  end

  #設定を戻す
  @root = WIKI_ROOT
  renderer.set_wiki_mode
  
  # フック
  if File.exist?('post-generation.rb') then
    system('ruby post-generation.rb')
  end
end


