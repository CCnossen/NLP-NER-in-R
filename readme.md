This script relies on ApacheOpen NLP to run Named Entity Recognition (NER) so as to derive a graph of Nodes/Edges. This set-up in R is used by myself as a benchmark (including all kinds of noise) of what other NER algorithms should capture (e.g. Transformers-based algorithms, Spacy, etc) from a given source of data

The output is a list of entities, which are joined on itself to create a Nodes/Edges framework. This could be useful if multiple sources (hence the iterative set-up) are scraped with NER to create a graph database.

Reference to OpenNLP: http://datacube.wu.ac.at/