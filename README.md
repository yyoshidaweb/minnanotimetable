# 🎤 みんなのタイムテーブル（β）
文字を入力するだけでタイムテーブルができる。\
スマホでもPCでも、誰でも使えるタイムテーブル作成サービス。

## サービスURL
https://minnanotimetable.com

## トップページのスクリーンショット

<img width="300" alt="スマートフォンでトップページを表示した際のスクリーンショット" src="https://github.com/user-attachments/assets/1f7d060c-872c-4df3-9f48-ea29442c310d" />



## デモ動画

<img width="300" alt="スマートフォンでタイムテーブルに出演情報を追加している場面のGIF画像" src="https://github.com/user-attachments/assets/c5a97ae9-1b15-4de4-856f-2ecfec9408a8" />



🎥 [フルのデモ動画を見る（約38秒）→](https://github.com/user-attachments/assets/9aee078f-4536-40a7-8e22-44cd3f3c29d4)



---

## サービス概要

「みんなのタイムテーブル」は、
音楽フェスやライブイベントなどのタイムテーブルを見やすく作成できるWebサービスです。

従来の画像形式のタイムテーブルでは、

* スマホで見づらい
* 拡大しないと読めない

といった課題があります。

本サービスは、これらの課題を解決することを目的に開発しています。



## 想定ユーザー

* イベント参加者
* 音楽フェス主催者
* ライブイベント運営者

将来的には、音楽フェス主催者の公式タイムテーブル作成ツールとしても利用されることを目標にしています。



## 主な機能

* タイムテーブル作成
* 公開用URL発行
* Googleアカウントログイン
* レスポンシブ対応



## 技術スタック

* Ruby
* Ruby on Rails
* SQLite（開発・ステージング・本番すべての環境で採用）
* Tailwind CSS
* Google OAuth
* Render（ホスティング）
* Puma（Webサーバー）

依存関係のバーションは [Dependabot](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/secure-your-dependencies/configuring-dependabot-security-updates) によって週1回アップデートしており、セキュリティ・安定性を保っています。



## ローカル開発環境構築手順

### 必要環境

* Ruby
* Bundler
* Node.js
* mise

### セットアップ手順

```
# リポジトリをクローン
git clone https://github.com/yyoshidaweb/minnanotimetable.git

# クローンしたディレクトリに移動
cd minnanotimetable

# miseの設定を信頼
mise trust

# 指定バージョンのランタイムをインストール
mise install

# gem インストール
bundle install

# DBセットアップ
bin/rails db:prepare

# サーバー起動（開発モード）
bin/dev
```

[http://localhost:3000](http://localhost:3000) で起動します。

※Googleログインは環境ごとにクライアントIDとクライアントシークレットを発行する必要があるため、次の手順を実行後に利用可能になります。

### Googleログインを利用するための設定

[Google認証機能作成手順 · yyoshidaweb/minnanotimetable Wiki](https://github.com/yyoshidaweb/minnanotimetable/wiki/Google%E8%AA%8D%E8%A8%BC%E6%A9%9F%E8%83%BD%E4%BD%9C%E6%88%90%E6%89%8B%E9%A0%86) を参考にして、Googleログインに必要なクライアントIDとクライアントシークレットを正しく設定すると、Googleログインが利用可能になります。





## テスト実行

```bash
bin/rails test
```



## 本番環境構成

* ホスティング先：Render（Starter instance）
* DB：SQLite（Renderの永続化ディスク（Persistent Disks）を利用）



## デプロイフロー

1. プルリクエスト作成時にRenderが [Pull Request Previews](https://render.com/docs/service-previews) 機能によってプレビュー環境を作成

2. プルリクエストを`main`ブランチにマージするとRenderが自動デプロイ
    - 同時にステージング環境にも同じ内容が自動デプロイされます



## 今後の予定

* タイムテーブルタブにSNS共有ボタンを追加する
* ページタイトルを動的に変化させる
* ページごとに適切なOGP画像を設定する
* マイタイムテーブル作成機能を実装
* 削除ボタンを一覧ページのオーバーフローメニューに移動させる
* etc...

リアルタイムの開発状況は [カンバン](https://github.com/users/yyoshidaweb/projects/2) でも確認できます。


---

## 制作背景

以前、音楽フェス「下北沢にて'24」で、あるバンドのMC中に「出演者が多すぎてタイムテーブルがすごく細かくなっている」という話を聞きました。

このとき、「誰でも簡単に見やすいタイムテーブルを作れるサービスがあったらいいのに」と思ったことがきっかけです。


## フィードバックを募集しています

現在β版のため、仕様変更やUI改善を随時行っています。\
ご意見・ご要望など、 [みんなのタイムテーブル お問い合わせフォーム](https://docs.google.com/forms/d/e/1FAIpQLSfJBlhMJb4MWDX_xWlc2lel1P_X5zGTmySXlcWU7De_XtSJmw/viewform) からフィードバックをくれると嬉しいです。



## 💡 さらに詳しい内容をまとめたWikiもあります
[Home · yyoshidaweb/minnanotimetable Wiki](https://github.com/yyoshidaweb/minnanotimetable/wiki) に要件定義書やシーケンス図、ER図、開発中に詰まったポイントのTipsなどをまとめています。\
ぜひご覧ください。

## ライセンス

本リポジトリのコードの著作権は作者に帰属します。\
許可なく複製・改変・再配布・商用利用することを禁止します。
