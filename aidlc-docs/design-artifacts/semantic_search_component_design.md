# Semantic Search Component Design

## Overview

The Semantic Search component enables natural language queries over the knowledge base using vector embeddings and similarity search. It combines Sentence Transformers for embedding generation with ChromaDB for efficient vector search.

## Component Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  Semantic Search Service                     │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │  Query Interface                                    │    │
│  │  - Natural Language Input                           │    │
│  │  - Query Validation                                 │    │
│  │  - Response Formatting                              │    │
│  └────────────────┬───────────────────────────────────┘    │
│                   │                                          │
│  ┌────────────────▼───────────────────────────────────┐    │
│  │  Query Processor                                    │    │
│  │  - Query Expansion                                  │    │
│  │  - Intent Detection                                 │    │
│  │  - Query Optimization                               │    │
│  └────────────────┬───────────────────────────────────┘    │
│                   │                                          │
│  ┌────────────────▼───────────────────────────────────┐    │
│  │  Embedding Generator                                │    │
│  │  - Sentence Transformers                            │    │
│  │  - Model: all-MiniLM-L6-v2                         │    │
│  │  - Embedding Cache                                  │    │
│  └────────────────┬───────────────────────────────────┘    │
│                   │                                          │
│  ┌────────────────▼───────────────────────────────────┐    │
│  │  Vector Search Engine                               │    │
│  │  - Similarity Computation                           │    │
│  │  - Result Ranking                                   │    │
│  │  - Relevance Filtering                              │    │
│  └────────────────┬───────────────────────────────────┘    │
│                   │                                          │
│  ┌────────────────▼───────────────────────────────────┐    │
│  │  Context Builder                                    │    │
│  │  - Result Aggregation                               │    │
│  │  - Context Formatting                               │    │
│  │  - Source Attribution                               │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. Embedding Generator

Uses Sentence Transformers to convert text into vector embeddings.

```python
from sentence_transformers import SentenceTransformer
from typing import List, Union
import numpy as np

class EmbeddingGenerator:
    """Generate embeddings using Sentence Transformers."""
    
    def __init__(self, model_name: str = "all-MiniLM-L6-v2"):
        """Initialize with a specific model."""
        self.model = SentenceTransformer(model_name)
        self.dimension = self.model.get_sentence_embedding_dimension()
        self.model_name = model_name
    
    def encode_query(self, query: str) -> List[float]:
        """Encode a single query."""
        embedding = self.model.encode(query, convert_to_numpy=True)
        return embedding.tolist()
    
    def encode_documents(self, documents: List[str]) -> List[List[float]]:
        """Encode multiple documents."""
        embeddings = self.model.encode(
            documents,
            batch_size=32,
            show_progress_bar=True,
            convert_to_numpy=True
        )
        return embeddings.tolist()
    
    def encode_batch(
        self,
        texts: List[str],
        batch_size: int = 32
    ) -> List[List[float]]:
        """Encode texts in batches for efficiency."""
        embeddings = self.model.encode(
            texts,
            batch_size=batch_size,
            show_progress_bar=False,
            convert_to_numpy=True
        )
        return embeddings.tolist()
```

### 2. Query Processor

Enhances and optimizes queries before embedding generation.

```python
import re
from typing import List, Dict

class QueryProcessor:
    """Process and optimize queries for semantic search."""
    
    def __init__(self):
        self.stop_words = set(['the', 'a', 'an', 'and', 'or', 'but'])
    
    def clean_query(self, query: str) -> str:
        """Clean and normalize query text."""
        # Remove extra whitespace
        query = re.sub(r'\s+', ' ', query).strip()
        
        # Convert to lowercase for consistency
        query = query.lower()
        
        return query
    
    def expand_query(self, query: str) -> List[str]:
        """Generate query variations for better results."""
        variations = [query]
        
        # Add question variations
        if not query.endswith('?'):
            variations.append(f"{query}?")
        
        # Add imperative form
        if query.startswith('how'):
            variations.append(query.replace('how to', 'steps to'))
        
        return variations
    
    def detect_intent(self, query: str) -> Dict[str, any]:
        """Detect query intent and parameters."""
        intent = {
            'type': 'general',
            'requires_list': False,
            'requires_explanation': False,
            'time_sensitive': False
        }
        
        # Question type detection
        if query.lower().startswith(('what', 'who', 'when', 'where')):
            intent['type'] = 'factual'
        elif query.lower().startswith(('how', 'why')):
            intent['type'] = 'explanatory'
            intent['requires_explanation'] = True
        elif query.lower().startswith(('list', 'show', 'find')):
            intent['requires_list'] = True
        
        # Time sensitivity
        time_keywords = ['recent', 'latest', 'current', 'today', 'now']
        if any(kw in query.lower() for kw in time_keywords):
            intent['time_sensitive'] = True
        
        return intent
```

### 3. Vector Search Engine

Performs similarity search and ranks results.

```python
from typing import List, Dict, Optional
import numpy as np

class VectorSearchEngine:
    """Search engine for vector similarity."""
    
    def __init__(self, chromadb_client):
        self.db_client = chromadb_client
        self.default_n_results = 5
        self.min_similarity_threshold = 0.5
    
    def search(
        self,
        query_embedding: List[float],
        n_results: int = None,
        metadata_filter: Optional[Dict] = None,
        min_similarity: float = None
    ) -> Dict:
        """Perform vector similarity search."""
        n_results = n_results or self.default_n_results
        min_similarity = min_similarity or self.min_similarity_threshold
        
        # Query ChromaDB
        raw_results = self.db_client.search(
            query_embedding=query_embedding,
            n_results=n_results * 2,  # Get more results for filtering
            metadata_filter=metadata_filter
        )
        
        # Filter by similarity threshold
        filtered_results = self._filter_by_similarity(
            raw_results,
            min_similarity
        )
        
        # Rank results
        ranked_results = self._rank_results(filtered_results)
        
        return ranked_results[:n_results]
    
    def _filter_by_similarity(
        self,
        results: Dict,
        min_similarity: float
    ) -> Dict:
        """Filter results by minimum similarity score."""
        filtered = {
            'ids': [],
            'documents': [],
            'metadatas': [],
            'distances': [],
            'similarities': []
        }
        
        for i, distance in enumerate(results['distances'][0]):
            # Convert distance to similarity (cosine similarity)
            similarity = 1 - distance
            
            if similarity >= min_similarity:
                filtered['ids'].append(results['ids'][0][i])
                filtered['documents'].append(results['documents'][0][i])
                filtered['metadatas'].append(results['metadatas'][0][i])
                filtered['distances'].append(distance)
                filtered['similarities'].append(similarity)
        
        return filtered
    
    def _rank_results(self, results: Dict) -> List[Dict]:
        """Rank and format results."""
        ranked = []
        
        for i in range(len(results['ids'])):
            ranked.append({
                'id': results['ids'][i],
                'document': results['documents'][i],
                'metadata': results['metadatas'][i],
                'similarity': results['similarities'][i],
                'rank': i + 1
            })
        
        return ranked
    
    def search_with_reranking(
        self,
        query: str,
        query_embedding: List[float],
        n_results: int = 5
    ) -> List[Dict]:
        """Search with result re-ranking based on query match."""
        # Initial vector search
        results = self.search(query_embedding, n_results=n_results * 2)
        
        # Re-rank based on keyword overlap
        reranked = self._rerank_by_keywords(query, results)
        
        return reranked[:n_results]
    
    def _rerank_by_keywords(
        self,
        query: str,
        results: List[Dict]
    ) -> List[Dict]:
        """Re-rank results based on keyword overlap."""
        query_terms = set(query.lower().split())
        
        for result in results:
            doc_terms = set(result['document'].lower().split())
            overlap = len(query_terms & doc_terms)
            
            # Combine similarity score with keyword overlap
            result['final_score'] = (
                result['similarity'] * 0.7 +
                (overlap / len(query_terms)) * 0.3
            )
        
        # Sort by final score
        return sorted(results, key=lambda x: x['final_score'], reverse=True)
```

### 4. Context Builder

Formats search results for AI consumption.

```python
from typing import List, Dict
from datetime import datetime

class ContextBuilder:
    """Build context from search results for AI."""
    
    def __init__(self):
        self.max_context_length = 4000  # characters
    
    def build_context(
        self,
        query: str,
        results: List[Dict],
        include_metadata: bool = True
    ) -> str:
        """Build formatted context from search results."""
        context_parts = [
            f"Query: {query}\n",
            f"Retrieved {len(results)} relevant documents:\n\n"
        ]
        
        for i, result in enumerate(results, 1):
            context_parts.append(f"--- Document {i} ---")
            context_parts.append(f"Relevance Score: {result['similarity']:.2f}")
            
            if include_metadata:
                metadata = result['metadata']
                context_parts.append(f"Source: {metadata.get('source', 'Unknown')}")
                context_parts.append(f"Title: {metadata.get('title', 'Untitled')}")
                
                if 'created_at' in metadata:
                    context_parts.append(f"Date: {metadata['created_at']}")
            
            context_parts.append(f"\nContent:\n{result['document']}\n")
        
        full_context = "\n".join(context_parts)
        
        # Truncate if too long
        if len(full_context) > self.max_context_length:
            full_context = full_context[:self.max_context_length] + "...\n[Content truncated]"
        
        return full_context
    
    def build_structured_context(
        self,
        query: str,
        results: List[Dict]
    ) -> Dict:
        """Build structured context object."""
        return {
            'query': query,
            'timestamp': datetime.utcnow().isoformat(),
            'result_count': len(results),
            'sources': [
                {
                    'rank': result['rank'],
                    'content': result['document'],
                    'metadata': result['metadata'],
                    'relevance': result['similarity'],
                    'id': result['id']
                }
                for result in results
            ]
        }
    
    def build_citation_text(self, results: List[Dict]) -> str:
        """Build citation text for sources."""
        citations = []
        
        for i, result in enumerate(results, 1):
            metadata = result['metadata']
            source = metadata.get('source', 'Unknown')
            title = metadata.get('title', 'Untitled')
            
            citation = f"[{i}] {title} ({source})"
            citations.append(citation)
        
        return "\n".join(citations)
```

## Complete Semantic Search Service

```python
from typing import List, Dict, Optional
import logging

logger = logging.getLogger(__name__)

class SemanticSearchService:
    """Complete semantic search service."""
    
    def __init__(
        self,
        embedding_generator: EmbeddingGenerator,
        chromadb_client,
        model_name: str = "all-MiniLM-L6-v2"
    ):
        self.embedding_generator = embedding_generator
        self.query_processor = QueryProcessor()
        self.search_engine = VectorSearchEngine(chromadb_client)
        self.context_builder = ContextBuilder()
    
    def search(
        self,
        query: str,
        n_results: int = 5,
        metadata_filter: Optional[Dict] = None,
        include_context: bool = True
    ) -> Dict:
        """Perform complete semantic search."""
        try:
            # 1. Process query
            cleaned_query = self.query_processor.clean_query(query)
            intent = self.query_processor.detect_intent(cleaned_query)
            
            # 2. Generate embedding
            query_embedding = self.embedding_generator.encode_query(cleaned_query)
            
            # 3. Search vector database
            results = self.search_engine.search(
                query_embedding=query_embedding,
                n_results=n_results,
                metadata_filter=metadata_filter
            )
            
            # 4. Build context
            context = None
            if include_context and results:
                context = self.context_builder.build_context(
                    query=cleaned_query,
                    results=results
                )
            
            # 5. Return complete response
            return {
                'query': query,
                'cleaned_query': cleaned_query,
                'intent': intent,
                'results': results,
                'context': context,
                'result_count': len(results)
            }
        
        except Exception as e:
            logger.error(f"Search failed: {e}")
            return {
                'query': query,
                'error': str(e),
                'results': [],
                'result_count': 0
            }
    
    def search_with_feedback(
        self,
        query: str,
        n_results: int = 5,
        positive_doc_ids: List[str] = None,
        negative_doc_ids: List[str] = None
    ) -> Dict:
        """Search with user feedback for improved results."""
        # Initial search
        search_results = self.search(query, n_results=n_results * 2)
        
        if positive_doc_ids or negative_doc_ids:
            # Re-rank based on feedback
            results = self._rerank_with_feedback(
                search_results['results'],
                positive_doc_ids or [],
                negative_doc_ids or []
            )
            search_results['results'] = results[:n_results]
        
        return search_results
    
    def _rerank_with_feedback(
        self,
        results: List[Dict],
        positive_ids: List[str],
        negative_ids: List[str]
    ) -> List[Dict]:
        """Re-rank results based on user feedback."""
        for result in results:
            doc_id = result['id']
            
            # Boost positive feedback
            if doc_id in positive_ids:
                result['similarity'] *= 1.5
            
            # Penalize negative feedback
            if doc_id in negative_ids:
                result['similarity'] *= 0.5
        
        # Re-sort by adjusted similarity
        return sorted(results, key=lambda x: x['similarity'], reverse=True)
    
    def multi_query_search(
        self,
        queries: List[str],
        n_results: int = 5
    ) -> Dict:
        """Search with multiple related queries."""
        all_results = {}
        combined_results = []
        
        for query in queries:
            results = self.search(query, n_results=n_results)
            all_results[query] = results
            combined_results.extend(results['results'])
        
        # Deduplicate and merge results
        seen_ids = set()
        unique_results = []
        
        for result in combined_results:
            if result['id'] not in seen_ids:
                seen_ids.add(result['id'])
                unique_results.append(result)
        
        # Sort by similarity
        unique_results.sort(key=lambda x: x['similarity'], reverse=True)
        
        return {
            'queries': queries,
            'individual_results': all_results,
            'combined_results': unique_results[:n_results],
            'result_count': len(unique_results[:n_results])
        }
```

## Advanced Features

### Hybrid Search (Vector + Keyword)

```python
class HybridSearchEngine:
    """Combine vector and keyword search."""
    
    def __init__(self, vector_search_engine, chromadb_client):
        self.vector_search = vector_search_engine
        self.db_client = chromadb_client
    
    def hybrid_search(
        self,
        query: str,
        query_embedding: List[float],
        n_results: int = 5,
        vector_weight: float = 0.7,
        keyword_weight: float = 0.3
    ) -> List[Dict]:
        """Perform hybrid vector + keyword search."""
        # Vector search
        vector_results = self.vector_search.search(
            query_embedding=query_embedding,
            n_results=n_results * 2
        )
        
        # Keyword search (simple implementation)
        keyword_results = self._keyword_search(query, n_results * 2)
        
        # Merge and re-rank
        merged = self._merge_results(
            vector_results,
            keyword_results,
            vector_weight,
            keyword_weight
        )
        
        return merged[:n_results]
    
    def _keyword_search(self, query: str, n_results: int) -> List[Dict]:
        """Simple keyword search implementation."""
        # This would integrate with a keyword search engine
        # For now, returns empty list (to be implemented)
        return []
    
    def _merge_results(
        self,
        vector_results: List[Dict],
        keyword_results: List[Dict],
        vector_weight: float,
        keyword_weight: float
    ) -> List[Dict]:
        """Merge and re-rank results from both methods."""
        result_map = {}
        
        # Add vector results
        for result in vector_results:
            result_map[result['id']] = {
                **result,
                'final_score': result['similarity'] * vector_weight
            }
        
        # Add/merge keyword results
        for result in keyword_results:
            if result['id'] in result_map:
                result_map[result['id']]['final_score'] += (
                    result['score'] * keyword_weight
                )
            else:
                result_map[result['id']] = {
                    **result,
                    'final_score': result['score'] * keyword_weight
                }
        
        # Sort by final score
        merged = sorted(
            result_map.values(),
            key=lambda x: x['final_score'],
            reverse=True
        )
        
        return merged
```

## Performance Optimization

### Embedding Cache

```python
from functools import lru_cache
import hashlib

class CachedEmbeddingGenerator(EmbeddingGenerator):
    """Embedding generator with caching."""
    
    def __init__(self, model_name: str = "all-MiniLM-L6-v2"):
        super().__init__(model_name)
        self.cache = {}
    
    def encode_query(self, query: str) -> List[float]:
        """Encode with caching."""
        cache_key = hashlib.md5(query.encode()).hexdigest()
        
        if cache_key in self.cache:
            return self.cache[cache_key]
        
        embedding = super().encode_query(query)
        self.cache[cache_key] = embedding
        
        return embedding
```

## Testing

```python
import pytest

def test_embedding_generation():
    """Test embedding generation."""
    generator = EmbeddingGenerator()
    embedding = generator.encode_query("test query")
    
    assert len(embedding) == 384
    assert all(isinstance(x, float) for x in embedding)

def test_query_processing():
    """Test query processing."""
    processor = QueryProcessor()
    
    cleaned = processor.clean_query("  What is   AI?  ")
    assert cleaned == "what is ai?"
    
    intent = processor.detect_intent("How does this work?")
    assert intent['type'] == 'explanatory'

def test_semantic_search():
    """Test semantic search service."""
    # Mock components
    generator = EmbeddingGenerator()
    # ... create mocked chromadb_client
    
    service = SemanticSearchService(generator, chromadb_client)
    results = service.search("test query")
    
    assert 'results' in results
    assert 'context' in results
```

## References

- [Sentence Transformers Documentation](https://www.sbert.net/)
- [Semantic Search Best Practices](https://www.pinecone.io/learn/semantic-search/)
- [RAG Implementation Guide](https://python.langchain.com/docs/use_cases/question_answering/)
