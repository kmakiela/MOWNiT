# MOWNiT
Computational Methods in Science and Technology Course at AGH
## First project:
```
Przygotuj program pozwalający na analizę obwodu elektrycznego z wykorzystaniem II 
prawa Kirchhoffa. Dane wejściowe to graf opisujący układ połączeń układu elektrycznego wraz z oporami, lista krotek (a,b,E) opisujących między którymi węzłami przyłożono jaką SEM oraz opór elektryczny poszczególnych połączeń.
Na wyjściu program powinien wygenerować graf ważony, gdzie waga krawędzi powinna odpowiadać natężeniu prądu na odpowiadającym jej połączeniu w obwodzie
```
## NLP project:
```
a)
Przygotuj duży korpus tekstów w języku angielskim, np. korzystając z web crawlera lub wikipedii. 
b)
Przygotuj zbiór słów występujących w dokumentach (słownik), następnie wykonaj embedding bag of words. Policz także częstość występowania poszczególnych słów.
c)
Przygotuj program akceptujący zapytanie użytkownika. Wektory zapisz w formie macierzowej (kolejne wiersze to kolejne słowa).
d)
Zaproponuj reprezentację całego dokumentu (oraz zapytania) w oparciu o reprezentacje poszczególnych słów.Poprawna reprezentacja nie powinna faworyzować dokumentów ze względu na ich długość (warto sprawdzić czemu).
e)
Do oceny podobieństwa zastosuj metrykę cosinusową. Zwróć knajbardziej podobnych wektorów (najlepiej w przyjaznej dla usera formie -tytuły dokumentów?)
f)
Zbadaj jak zachowa się wyszukiwarka po aproksymacji macierzy BoW metodą SVD low rank approximation. Dla jakiego rzędu macierzy (bezwzględnego i względem rozmiaru macierzy BoW) wyniki są najlepsze/najgorsze,dlaczego?
g)
Aby zmniejszyć wagę występujących słów, które występują w dużej ilości dokumentów, pomnóż każdy one hot vectorprzez odpowiednią liczbę, wyliczoną jako logarytm ze stosunku ilości dokumentów do ilości dokumentów, w których dane słowo występuje co najmniej raz -podejście to znane jest jako TF-IDF. Sprawdź wpływ TF-IDF na działanie wyszukiwarki
```
