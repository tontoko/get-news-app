class String
  def sjisable
    str = self
    #変換テーブル上の文字を下の文字に置換する
    from_chr = "\u{301C 2212 00A2 00A3 00AC 2013 2014 2016 203E 00A0 00F8 203A}"
    to_chr   = "\u{FF5E FF0D FFE0 FFE1 FFE2 FF0D 2015 2225 FFE3 0020 03A6 3009}"
    str.tr!(from_chr, to_chr)
    #変換テーブルから漏れた不正文字は?に変換し、さらにUTF8に戻すことで今後例外を出さないようにする
    str = str.encode("Windows-31J","UTF-8",:invalid => :replace,:undef=>:replace).encode("UTF-8","Windows-31J")
  end
end

class GetNewsController < ApplicationController
    require "open-uri"
    require "nokogiri"
    require "csv"
    
    def index
    end
    
    def download
        filepath = Rails.root.join('yahooNews.csv')
        stat = File::stat(filepath)
        send_file(filepath, :filename => 'yahooNews.csv', :length => stat.size)
    end
    
    def get_news
        @category = params[:category]
        @keyword = params[:keyword]
        
        if !@category.empty? && !@keyword.empty?
            url = "https://news.yahoo.co.jp/search/?p=#{@keyword}&c_=#{@category}"
            res = scrapingWithKeyword(url)
        elsif !@keyword.empty?
            url = "https://news.yahoo.co.jp/search/?p=#{@keyword}"
            res = scrapingWithKeyword(url)
        elsif !@category.empty?
            url = "https://news.yahoo.co.jp/list/?c="
            res = scrapingWithCategory(url, @category)
        else
            url = "https://news.yahoo.co.jp/list/"
            res = scrapingTopics(url)
        end

        unless res == false
            CSV.open("yahooNews.csv", "w", :encoding => "SJIS") do |csv|
              csv << res[0]
              csv << res[1]
            end
        else
            flash[:message] = "この条件ではスクレイピングできません"
        end

        redirect_to root_path
        
    end
    
    private
    
        def scrapingWithKeyword(url)
            charset = nil
        
            html = open(URI.encode url) do |f|
                charset = f.charset
                f.read
            end
            
            doc = Nokogiri::HTML.parse(html, nil, charset)
            docs = [[], []]
            doc.xpath('//div[@class="l cf"]').each do |node|
              docs[0].push(node.css('.t > a').inner_text)
              docs[1].push(node.css('.txt > p > .d').inner_text.sjisable)
            end
            
            return docs
        end
        
        def scrapingWithCategory(url, category)
            charset = nil
            urlWithCategory2 = nil
            
            case category
                when "dom"
                    rep_url = "domestic"
                when "c_int"
                    rep_url = "world"
                when "bus"
                    rep_url = "economy"
                when "c_ent"
                    rep_url = "entertainment"
                when "c_spo"
                    rep_url = "sports"
                when "c_sci"
                    rep_url = "science"
                    rep_url2 = "computer"
                when "c_life"
                    rep_url = "life"
                    return false
                when "loc"
                    rep_url = "local"
                else
                    return false
            end
                
            urlWithCategory = url + rep_url
            urlWithCategory2 = url + rep_url2 if rep_url2
            
            html = open(URI.encode urlWithCategory) do |f|
                charset = f.charset
                f.read
            end
            
            doc = Nokogiri::HTML.parse(html, nil, charset)
            docs = [[], []]
            doc.xpath('//dl[@class="title"]').each do |node|
              docs[0].push(node.css('dt').inner_text)
              docs[1].push(node.css('dd > time').inner_text.sjisable)
            end
            
            if urlWithCategory2 then
                html2 = open(URI.encode urlWithCategory2) do |f|
                    charset = f.charset
                    f.read
                end
                doc = Nokogiri::HTML.parse(html2, nil, charset)
                doc.xpath('//dl[@class="title"]').each do |node|
                  docs[0].push(node.css('dt').inner_text)
                  docs[1].push(node.css('dd > time').inner_text.sjisable)
                end
            end
            
            return docs
        end
    
        def scrapingTopics(url)
            charset = nil
        
            html = open(URI.encode url) do |f|
                charset = f.charset
                f.read
            end
            
            doc = Nokogiri::HTML.parse(html, nil, charset)
            docs = [[], []]
            doc.xpath('//dl[@class="title"]').each do |node|
              docs[0].push(node.css('dt').inner_text)
              docs[1].push(node.css('dd > time').inner_text.sjisable)
            end
            
            return docs
        end
end
