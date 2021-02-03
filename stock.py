import requests
import pandas as pd
import time


def twse_date():
    try:
        date = dateinput[0:4]+dateinput[5:7]+dateinput[8:10]
        r = requests.get('https://www.twse.com.tw/fund/T86?response=json&date=' + date + '&selectType=ALL', timeout=15)
        stock3rd = r.json()
        del stock3rd['stat']
        del stock3rd['date']
        del stock3rd['title']
        dfcol = list(stock3rd['fields'])
        df = pd.DataFrame(stock3rd['data'], columns=dfcol)
        df = pd.DataFrame(df[['證券代號', '證券名稱', '外陸資買賣超股數(不含外資自營商)', '投信買賣超股數']])
        df = df.rename(columns={'證券代號': 'code',
                                '證券名稱': 'name',
                                '外陸資買賣超股數(不含外資自營商)': 'foreign',
                                '投信買賣超股數': 'credit'})
        df['date'] = dateinput
        pd.DataFrame.to_csv(df, './三大法人買賣超/' + dateinput + '-3rd.csv', index=False, encoding='ansi')
        print('done!')
    except Exception as e:
        print('something wrong.')


def twse():
    for i in range(0, len(datelist)):
        try:
            date = datelist[i][0:4]+datelist[i][5:7]+datelist[i][8:10]
            r = requests.get('https://www.twse.com.tw/fund/T86?response=json&date=' + date + '&selectType=ALL', timeout=15)
            stock3rd = r.json()
            del stock3rd['stat']
            del stock3rd['date']
            del stock3rd['title']
            dfcol = list(stock3rd['fields'])
            df = pd.DataFrame(stock3rd['data'], columns=dfcol)
            df = pd.DataFrame(df[['證券代號', '證券名稱', '外陸資買賣超股數(不含外資自營商)', '投信買賣超股數']])
            df = df.rename(columns={'證券代號': 'code',
                                    '證券名稱': 'name',
                                    '外陸資買賣超股數(不含外資自營商)': 'foreign',
                                    '投信買賣超股數': 'credit'})
            df['date'] = datelist[i]
            pd.DataFrame.to_csv(df, './三大法人買賣超/' + datelist[i] + '-3rd.csv', index=False, encoding='ansi')
            print(datelist[i] + ' is get')
        except Exception as e:
            print(str(i) + ' in error')
        finally:
            time.sleep(10)
    print('done!')


while __name__ == '__main__':
    mode = input('mode is [day / history]?\n')
    if mode == 'day':
        dateinput = input('date=?\n')
        twse_date()
    elif mode == 'history':
        datedb = pd.read_csv('./history.csv')
        datelist = list(datedb['date'])
        print('days = ' + str(len(datelist)))
        twse()
    else:
        pass
    ans = input('enter any key to exit.')

