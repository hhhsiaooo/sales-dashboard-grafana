# 銷售分析儀表板
這是一個銷售分析儀表板，基於 `寵物用品銷售資料產生器` 生成的模擬資料，設計銷售分析指標，並使用開源軟體 [Grafana][grafana-link] 介接 [PostgreSQL][postgresql-link] 資料庫進行視覺化。
> 儀表板頁面截圖請參照 `整體會員樣態頁面.jpg`、`年度比較頁面.jpg`、`短期比較頁面.jpg`。

## 指標規劃
為瞭解銷售的長期趨勢與短期波動，從`不分時間`、`年度`、`周`三個時間維度進行指標規劃，並根據各項指標要傳達的資訊，選擇合適且直觀的圖表類型。
* 不分時間：不分時間的會員與商品統計資訊。瞭解忠實客戶樣態與主力商品。
  * 註冊會員數
  * 新註冊會員數月趨勢
  * 會員性別比例
  * 會員年齡比例
  * 商品購買次數
  * 商品購買金額
* 年度比較：比較今年與去年的訂單量與客單價，呈現商品銷售佔比。評估今年的銷售表現，並發現市場需求的變化，例如特定產品是否比去年更受歡迎。
  * 今年/去年訂單量
  * 今年/去年客單價
  * 各通路轉換次數
  * 各類商品購買次數
  * 各類商品購買金額
* 短期比較：比較本周與前周的商品銷售情形，並呈現本周購買會員樣態與轉換率，檢視促銷活動的影響，同時可以透過篩選器查看不同性別、年齡級距會員的購買情形，快速評估短期業績變動。
  * 本周訂單數
  * 本周購買會員樣態
  * 本周購買轉換率
  * 本周各類商品購買情形
  * 本周/前周促銷活動

## 儀表板製作
利用開源軟體 `Grafana` 製作銷售分析儀表板，支援多種資料來源，並提供豐富的圖表選擇。

#### Grafana 安裝
參考 [cherry server][install-link] 安裝教學。使用作業系統 `Ubuntu 22.04`，需先更新系統套件。
```
sudo apt update -y && sudo apt upgrade -y
```

安裝需要的套件。
* apt-transport-https 讓APT透過HTTPS下載套件。
* software-properties-common 管理APT套件。
* wget 安裝GPG金鑰。
```
sudo apt install -y apt-transport-https software-properties-common wget
```

新增 `Grafana GPG` 金鑰，驗證下載的套件為官方提供。
```
sudo mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
```

將 `Grafana` 加入 `Ubuntu APT repositories`。
```
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
sudo apt update
```

使用APT安裝 `Grafana`。
```
sudo apt install grafana
```

啟用服務，並設定開機自動啟動。
```
sudo grafana-server -v
sudo systemctl start grafana-server
sudo systemctl enable grafana-server
sudo systemctl status grafana-server
```

開啟防火牆port 3000，在瀏覽器輸入網址 `http://your_server_IP:3000` 即可查看 `Grafana` 網頁介面。
```
sudo ufw enable 
sudo ufw allow ssh
sudo ufw allow 3000/tcp
```

解除安裝 `Grafana`。
```
# 停止服務
sudo systemctl stop grafana-server
sudo systemctl disable grafana-server

# 完全移除 Grafana，包括設定檔
sudo apt remove --purge grafana -y

# 刪除所有關聯的資料夾與檔案
sudo rm -rf /var/lib/grafana
sudo rm -rf /etc/grafana
sudo rm -rf /var/log/grafana

# 更新系統
sudo apt autoremove -y
sudo apt clean
```

#### Grafana 使用者建立
設定儀表板用的資料庫使用者，權限設定為僅能讀取。
```
# 登入PostgreSQL資料庫
sudo -u postgres psql

# 設定使用者帳密
CREATE USER grafana WITH PASSWORD 'password';

# 設定權限
GRANT CONNECT ON DATABASE source_db TO grafana;
\c source_db
GRANT USAGE ON SCHEMA public TO grafana;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO grafana;

# 未來的新資料表也使用該權限
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO grafana;

# 檢查權限設定
\dp
```

在 Grafana 網頁介面中，新增不同權限的使用者。
* 管理者：進行帳號管理，可新增、共用及刪除儀表板畫
面。
* 檢視者：僅可檢視儀表板畫面。

設定步驟：
* 在 Grafana 網頁介面的左側功能列找到 `Administration`，點選 `Users and acess` 中的 `Users`，進入使用者列表。
* 進入使用者列表後，選擇 `New user`，輸入使用者的姓
名、電子郵件、登入帳號與密碼後，點選 `Create user` 即可創建新使
用者。
* 進入使用者列表後，選擇右側編輯按鈕，進入`User information` 頁面，點選 `Edit` 即可修改使用者基本資訊及權限。

#### 指標計算
根據指標圖表所需的資料格式，在 Grafana 網頁介面中，撰寫SQL Query從資料庫取得資料並計算指標。
> 請參照 `grafana_query.sql`。

#### 儀表板頁面
* 在 Grafana 網頁介面中，設定各圖表的資料欄位與樣式。
* 根據分析的日期區間與指標內容，儀表板分為`整體會員樣態`、`年度比較`、`短期比較`三個頁面。

#### 儀表板設定檔
在 Grafana 網頁介面中，可將各圖表的欄位介接設定與樣式，匯出成 JSON 檔案，未來於新主機或其他 Grafana 儀表板介面匯入此 JSON 檔案，在資料與欄位名稱不變的情況下，可復現儀表板圖表各項設定（例如：圖表類型、 XY 軸欄位、圖表顏色、字體大小）。
> 儀表板設定檔請參照 `整體會員樣態.json`、`年度比較.json`、`短期比較.json`。

* 設定檔匯出
  * 登入 Grafana 網頁介面。
  * 點選功能列中的 `Dashboards` ，進入要匯出的儀表板頁面。
  * 點選介面上方的按鈕 `Share` 。
  * 點選 `Export` 中的 `Save to file` ，儲存成 JSON 檔案。

* 資料來源設定
  * 匯入設定檔前，需先設定儀表板要介接的資料來源，該資料來源的資料內容與欄位名稱，需與先前匯出設定檔的儀表板一致。
  * 登入 Grafana 網頁介面。
  * 點選功能列中的 `Connections` -> `Data source` ，確認是否已新增要介接的資料來源。
  * 調整資料來源中的 `Name` 、 `Connection` 、 `Authentication` 等相關設定，並使用 `Save & test` 測試是否正常連線。

* 設定檔匯入
    * 點選功能列中的 `Dashboards` 進入儀表板介面。
    * 點選介面右上方的按鈕 `New` -> `Import` 。
    * 點選 `Load` 匯入儀表板設定檔 JSON file 。


## 授權條款
版權所有 2025 Hailey Hsiao， 作者保有所有權利。

## 作者
| Hailey Hsiao
| dwarfxiao@gmail.com

[grafana-link]: https://grafana.com/oss/grafana/
[postgresql-link]: https://www.postgresql.org/
[install-link]: https://www.cherryservers.com/blog/install-grafana-ubuntu