import faiss
import numpy as np
from sentence_transformers import SentenceTransformer

# 1. Initialize the embedding model (converts text to 384-dimensional vectors)
print("Loading text embedding model...")
model = SentenceTransformer("all-MiniLM-L6-v2")

# 2. Define your knowledge base / document inventory
documents = [
    "Python is a versatile programming language used for AI and web development.",
    "The golden retriever puppy barked excitedly at the red ball.",
    "Global stock markets experienced a minor downturn early this morning.",
    "To bake a perfect chocolate cake, ensure your eggs are room temperature.",
    "Machine learning models rely heavily on high-quality training datasets.",
    "The local cafe serves incredible espresso and fresh croissants every day.",
]

# 3. Generate embeddings and convert them to float32 NumPy arrays (required by FAISS)
print("Generating document embeddings...")
doc_embeddings = model.encode(documents)
doc_embeddings = np.array(doc_embeddings).astype("float32")

# 4. Initialize the FAISS index using basic L2 (Euclidean) distance
# The 'dimension' parameter must match the output size of the embedding model (384)
dimension = doc_embeddings.shape[1]
index = faiss.IndexFlatL2(dimension)

# 5. Populate the index with the document vectors
index.add(doc_embeddings)
print(f"Successfully indexed {index.ntotal} documents.\n")


# 6. Define a reusable function to search the index
def search_knowledge_base(query_text: str, top_k: int = 2):
    # Encode the user's query into the exact same vector space
    query_embedding = model.encode([query_text])
    query_embedding = np.array(query_embedding).astype("float32")

    # Perform the vector search
    # distances: L2 distance scores (lower scores = closer match)
    # indices: The corresponding numerical position of the matched item
    distances, indices = index.search(query_embedding, top_k)

    print(f'🔍 Query: "{query_text}"')
    print("-" * 50)
    for i in range(top_k):
        match_idx = indices[0][i]
        distance_score = distances[0][i]
        # Ignore fallback indices (-1) if top_k exceeds dataset size
        if match_idx != -1:
            print(f"Match #{i+1} (Distance: {distance_score:.4f}):")
            print(f"  -> {documents[match_idx]}")
    print("\n")


# 7. Run real test cases showing semantic understanding (not just keyword matching)
search_knowledge_base("Tell me about software engineering or artificial intelligence", top_k=2)
search_knowledge_base("I want some delicious morning breakfast and coffee", top_k=1)
search_knowledge_base("Is the economy doing well today?", top_k=1)

