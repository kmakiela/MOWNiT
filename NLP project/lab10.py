import wikipedia
import re
import numpy as np
import math


def get_words(text):
    return re.compile('\w+').findall(text)


def write_page_summary_to_file(title):
    f = open(title + ".txt", "w+")
    f.write(wikipedia.summary(title))
    f.close


def get_page_summary(title):
    f = open(title + ".txt", "r+")
    s = f.read()
    f.close()
    return s


def create_bow_model(doc_list):
    all_words = []
    bow_model = []

    # find all words in all documents
    for doc in doc_list:
        word_list = get_words(doc)
        for word in word_list:
            if word not in all_words:
                all_words.append(word)

    # update BoW model by dictionary for each page
    for doc in doc_list:
        word_list = get_words(doc)
        doc_dict = {}
        for word in word_list:
            if word in doc_dict.keys():
                doc_dict.update({word: doc_dict.get(word) + 1})
            else:
                doc_dict.update({word: 1})
        for word in all_words:
            if word not in word_list:
                doc_dict.update({word: 0})
        bow_model.append(doc_dict)
    return sorted(all_words), bow_model


def calculate_tf_idf(all_words, bow):
    bow_array = np.zeros((len(bow), len(all_words)), dtype=float)
    for (index,  doc_dict) in enumerate(bow):
        for word in all_words:
            df = doc_dict.get(word)
            count = 0
            for doc in bow:
                if doc.get(word) > 0:
                    count += 1
            idf = math.log10((len(bow)/count))
            bow_array[index, all_words.index(word)] = df * idf
    return bow_array


# cos(x, y) = Σi xi*yi / [ sqrt(Σi xi^2) * sqrt(Σi yi^2) ]
# v1 and v2 are numpy arrays with one row
def calculate_cosinus_similarity(all_words, v1, v2):
    counter = 0
    denominator1 = 0
    denominator2 = 0
    for index, word in enumerate(all_words):
        counter += v1[index - 1] * v2[index - 1]
        denominator1 += math.pow(v1[index - 1], 2)
        denominator2 += math.pow(v2[index - 1], 2)
    denominator = math.sqrt(denominator1) * math.sqrt(denominator2)
    return counter / denominator


# query is one-row numpy array here
def find_best_document(query, all_words, bow):
    highest_cos = -1
    best_match_index = -1
    for index in range(0, bow.shape[0]):
        cos = calculate_cosinus_similarity(all_words, query, bow[index, :])
        if cos > highest_cos:
            highest_cos = cos
            best_match_index = index

    return best_match_index


# query is string here and returned is numpy array
def prepare_query(all_words, query):
    word_list = get_words(query)
    query_dict = {}
    for word in word_list:
        if word in query_dict.keys():
            query_dict.update({word: query_dict.get(word) + 1})
        else:
            query_dict.update({word: 1})
    for word in all_words:
        if word not in word_list:
            query_dict.update({word: 0})
#    return [query_dict]

    query_array = np.zeros(len(all_words), dtype=float)
    for word in all_words:
        amount = query_dict.get(word)
        query_array[all_words.index(word)] = amount
    return query_array


def find_k_documents(titles, k, q, query, all_words, bow):
    bow_copy = bow
    print("Best matches for query: " + q)
    for i in range(k):
        index = find_best_document(query, all_words, bow_copy)
        match = titles[index]
        print(match)
        titles.remove(match)
        np.delete(bow_copy, index, 0)
    print()

def main():
    titles = ["Knife", "Otter", "Epica", "Shakespeare", "Tiger", "Julius Ceasar", "Sun", "Bridge", "Poker", "Sony"]
    documents = []
    for title in titles:
#        write_page_summary_to_file(title)
        documents.append(get_page_summary(title))

    all_words, bow = create_bow_model(documents)
    bow_array = calculate_tf_idf(all_words, bow)

#    for i in range(bow_array.shape[0]):
#        if np.any(bow_array[i, :]) == False:
#            print(i)

    query = "i like card games very much"
    prepared_query = prepare_query(all_words, query)
    find_k_documents(titles, 1, query, prepared_query, all_words, bow_array)

    query2 = "Why are all symphonic metal bands dutch?"
    prepared_query2 = prepare_query(all_words, query2)
    find_k_documents(titles, 2, query2, prepared_query2, all_words, bow_array)

    query3 = "Aggressive, carnivorous animals are better than passive herbivores"
    prepared_query3 = prepare_query(all_words, query3)
    find_k_documents(titles, 3, query3, prepared_query3, all_words, bow_array)


if __name__ == '__main__':
    main()
