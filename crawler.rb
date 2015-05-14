require 'capybara'
require 'nokogiri'
require 'pry'

class Crawler
  include Capybara::DSL

  def initialize
    Capybara.javascript_driver = :selenium
    Capybara.current_driver = :selenium
    @courses = []
  end

  def crawl
    visit "http://webs8.nptu.edu.tw/selectn/search.asp"
    dept_count = all('select[name="dept"] option:not(:first-child)').count
    sect_count = all('select[name="sect"] option:not(:first-child)').count
    grad_count = all('select[name="grade"] option:not(:first-child)').count

    dept_count.times do |dept|
    sect_count.times do |sect|
    grad_count.times do |grade|
      dept_option = all('select[name="dept"] option:not(:first-child)')[dept]
      sect_option = all('select[name="sect"] option:not(:first-child)')[sect]
      grade_option = all('select[name="grade"] option:not(:first-child)')[grade]

      dept_option.select_option
      sect_option.select_option
      grade_option.select_option

      dept_name = dept_option.value; sect_name = sect_option.value; grade_name = grade_option.value;

      first(:button, '確定').click
      File.open("1032/#{dept_name}-#{sect_name}-#{grade_name}.html", 'w') {|f| f.write(html)}


      # evaluate_script('window.history.back()')
      visit "http://webs8.nptu.edu.tw/selectn/search.asp"
    end end end
  end

  def parse
    Dir.glob('1032/*.html').each do |filename|
      doc = Nokogiri::HTML(File.read(filename))

      doc.css('table')[0].css('tr:not(:first-child)').each do |row|
        datas = row.css('td')

        required_raw = datas[3] && datas[3].text

        periods = []
        location = datas[18] && datas[18].text.strip
        datas[10..16].each_with_index do |data, d|
          m = data.text.match(/(?<p>\d+)/)
          if !!m && m[:p]
            m[:p].split("").each do |p|
              chars = []
              chars << d+1
              chars << p
              chars << location
              periods << chars.join(',')
            end
          end
        end

        @courses << {
          code: datas[0] && datas[0].text,
          name: datas[1] && datas[1].text,
          url: datas[1] && datas[1].css('a') && datas[1].css('a')[0] && datas[1].css('a')[0][:href],
          domain: datas[2] && datas[2].text.strip,
          required: required_raw && required_raw[1..-1].strip,
          credits: datas[4] && datas[4].text.to_i,
          lecturer: datas[9] && datas[9].text.strip,
          periods: periods
        }
      end
    end

    File.open('courses.json', 'w') {|f| f.write(JSON.pretty_generate(@courses))}
  end
end

crawler = Crawler.new
# crawler.crawl
crawler.parse
