# ChromaDB Component Design

## Overview

ChromaDB serves as the vector database for storing document embeddings and enabling fast semantic search. This document details the design, configuration, and integration of ChromaDB within the knowledge pipeline.

## Component Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    ChromaDB Component                        │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │  Client Interface                                   │    │
│  │  - Connection Manager                               │    │
│  │  - Query Builder                                    │    │
│  │  - Result Parser                                    │    │
│  └────────────────┬───────────────────────────────────┘    │
│                   │                                          │
│  ┌────────────────▼───────────────────────────────────┐    │
│  │  Collection Manager                                 │    │
│  │  - Create/Delete Collections                        │    │
│  │  - Schema Management                                │    │
│  │  - Index Management                                 │    │
│  └────────────────┬───────────────────────────────────┘    │
│                   │                                          │
│  ┌────────────────▼───────────────────────────────────┐    │
│  │  Vector Operations                                  │    │
│  │  - Add Embeddings                                   │    │
│  │  - Update Embeddings                                │    │
│  │  - Delete Embeddings                                │    │
│  │  - Query by Similarity                              │    │
│  └────────────────┬───────────────────────────────────┘    │
│                   │                                          │
│  ┌────────────────▼───────────────────────────────────┐    │
│  │  Persistence Layer                                  │    │
│  │  - Disk Storage (EFS)                               │    │
│  │  - Transaction Management                           │    │
│  │  - Data Integrity                                   │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## Configuration

### Basic Configuration

```python
import chromadb
from chromadb.config import Settings

# Client configuration
chroma_client = chromadb.Client(Settings(
    chroma_db_impl="duckdb+parquet",
    persist_directory="/mnt/efs/chromadb",
    anonymized_telemetry=False,
))
```

### Production Configuration

```python
import chromadb
from chromadb.config import Settings

# Production settings with EFS persistence
settings = Settings(
    chroma_db_impl="duckdb+parquet",
    persist_directory="/mnt/efs/chromadb",
    anonymized_telemetry=False,
    allow_reset=False,  # Prevent accidental data loss
)

client = chromadb.Client(settings)
```

## Collection Schema

### Knowledge Base Collection

```python
# Create collection with metadata
collection = client.create_collection(
    name="knowledge_base",
    metadata={
        "description": "Organizational knowledge documents",
        "embedding_model": "all-MiniLM-L6-v2",
        "dimension": 384,
    },
    embedding_function=None,  # We handle embeddings externally
)
```

### Document Metadata Schema

Each document stored in ChromaDB includes:

```python
{
    "id": "doc_12345",
    "embedding": [0.123, -0.456, ...],  # 384 dimensions
    "metadata": {
        "source": "policies/hr_handbook.pdf",
        "title": "HR Handbook - Chapter 3",
        "author": "HR Department",
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-06-20T14:22:00Z",
        "document_type": "policy",
        "section": "benefits",
        "page_number": 12,
        "chunk_index": 3,
        "tags": ["hr", "benefits", "policies"],
    },
    "document": "Text content of the document chunk..."
}
```

## Core Operations

### 1. Add Documents

```python
def add_documents(
    collection,
    documents: List[str],
    embeddings: List[List[float]],
    metadatas: List[dict],
    ids: List[str]
) -> None:
    """Add documents to the collection."""
    collection.add(
        documents=documents,
        embeddings=embeddings,
        metadatas=metadatas,
        ids=ids
    )
```

### 2. Query Documents

```python
def query_documents(
    collection,
    query_embedding: List[float],
    n_results: int = 5,
    metadata_filter: dict = None
) -> dict:
    """Query similar documents."""
    results = collection.query(
        query_embeddings=[query_embedding],
        n_results=n_results,
        where=metadata_filter,  # Optional metadata filtering
        include=["documents", "metadatas", "distances"]
    )
    return results
```

### 3. Update Documents

```python
def update_document(
    collection,
    document_id: str,
    document: str = None,
    embedding: List[float] = None,
    metadata: dict = None
) -> None:
    """Update an existing document."""
    collection.update(
        ids=[document_id],
        documents=[document] if document else None,
        embeddings=[embedding] if embedding else None,
        metadatas=[metadata] if metadata else None
    )
```

### 4. Delete Documents

```python
def delete_documents(
    collection,
    document_ids: List[str]
) -> None:
    """Delete documents by ID."""
    collection.delete(ids=document_ids)
```

### 5. Metadata Filtering

```python
def query_with_filters(
    collection,
    query_embedding: List[float],
    document_type: str = None,
    tags: List[str] = None,
    date_range: tuple = None
) -> dict:
    """Query with metadata filters."""
    where_clause = {}
    
    if document_type:
        where_clause["document_type"] = document_type
    
    if tags:
        where_clause["tags"] = {"$in": tags}
    
    if date_range:
        where_clause["created_at"] = {
            "$gte": date_range[0],
            "$lte": date_range[1]
        }
    
    return collection.query(
        query_embeddings=[query_embedding],
        n_results=5,
        where=where_clause
    )
```

## Integration with Knowledge Pipeline

### Client Wrapper Class

```python
from typing import List, Dict, Optional
import chromadb
from chromadb.config import Settings

class ChromaDBClient:
    """Wrapper class for ChromaDB operations."""
    
    def __init__(self, persist_directory: str = "/mnt/efs/chromadb"):
        self.settings = Settings(
            chroma_db_impl="duckdb+parquet",
            persist_directory=persist_directory,
            anonymized_telemetry=False,
            allow_reset=False,
        )
        self.client = chromadb.Client(self.settings)
        self.collection = None
    
    def initialize_collection(self, collection_name: str = "knowledge_base"):
        """Initialize or get existing collection."""
        try:
            self.collection = self.client.get_collection(name=collection_name)
        except Exception:
            self.collection = self.client.create_collection(
                name=collection_name,
                metadata={
                    "description": "Organizational knowledge documents",
                    "embedding_model": "all-MiniLM-L6-v2",
                    "dimension": 384,
                }
            )
    
    def add_documents_batch(
        self,
        documents: List[str],
        embeddings: List[List[float]],
        metadatas: List[Dict],
        ids: List[str]
    ) -> None:
        """Add a batch of documents."""
        if not self.collection:
            raise ValueError("Collection not initialized")
        
        self.collection.add(
            documents=documents,
            embeddings=embeddings,
            metadatas=metadatas,
            ids=ids
        )
    
    def search(
        self,
        query_embedding: List[float],
        n_results: int = 5,
        metadata_filter: Optional[Dict] = None
    ) -> Dict:
        """Search for similar documents."""
        if not self.collection:
            raise ValueError("Collection not initialized")
        
        return self.collection.query(
            query_embeddings=[query_embedding],
            n_results=n_results,
            where=metadata_filter,
            include=["documents", "metadatas", "distances"]
        )
    
    def get_collection_stats(self) -> Dict:
        """Get collection statistics."""
        if not self.collection:
            raise ValueError("Collection not initialized")
        
        count = self.collection.count()
        return {
            "document_count": count,
            "collection_name": self.collection.name,
            "metadata": self.collection.metadata,
        }
```

## Performance Optimization

### 1. Batch Operations

Process documents in batches for better performance:

```python
BATCH_SIZE = 100

def ingest_documents_batched(documents, embeddings, metadatas, ids):
    """Ingest documents in batches."""
    for i in range(0, len(documents), BATCH_SIZE):
        batch_docs = documents[i:i + BATCH_SIZE]
        batch_embs = embeddings[i:i + BATCH_SIZE]
        batch_meta = metadatas[i:i + BATCH_SIZE]
        batch_ids = ids[i:i + BATCH_SIZE]
        
        collection.add(
            documents=batch_docs,
            embeddings=batch_embs,
            metadatas=batch_meta,
            ids=batch_ids
        )
```

### 2. Index Optimization

Regular maintenance for optimal performance:

```python
def optimize_collection():
    """Perform collection optimization."""
    # ChromaDB handles indexing automatically
    # Ensure persist is called after bulk operations
    client.persist()
```

### 3. Query Optimization

Use appropriate parameters for queries:

```python
def optimized_search(query_embedding, min_relevance=0.7):
    """Search with relevance filtering."""
    results = collection.query(
        query_embeddings=[query_embedding],
        n_results=10,  # Get more results
        include=["documents", "metadatas", "distances"]
    )
    
    # Filter by distance threshold
    filtered_results = {
        "documents": [],
        "metadatas": [],
        "distances": []
    }
    
    for i, distance in enumerate(results["distances"][0]):
        similarity = 1 - distance  # Convert distance to similarity
        if similarity >= min_relevance:
            filtered_results["documents"].append(results["documents"][0][i])
            filtered_results["metadatas"].append(results["metadatas"][0][i])
            filtered_results["distances"].append(distance)
    
    return filtered_results
```

## Data Management

### Backup and Restore

```python
import shutil
from datetime import datetime

def backup_chromadb(persist_dir: str, backup_dir: str):
    """Backup ChromaDB data."""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = f"{backup_dir}/chromadb_backup_{timestamp}"
    shutil.copytree(persist_dir, backup_path)
    return backup_path

def restore_chromadb(backup_path: str, persist_dir: str):
    """Restore ChromaDB from backup."""
    shutil.rmtree(persist_dir, ignore_errors=True)
    shutil.copytree(backup_path, persist_dir)
```

### Data Migration

```python
def migrate_collection(old_collection, new_collection):
    """Migrate data between collections."""
    # Get all documents from old collection
    all_data = old_collection.get()
    
    # Add to new collection
    new_collection.add(
        ids=all_data["ids"],
        documents=all_data["documents"],
        embeddings=all_data["embeddings"],
        metadatas=all_data["metadatas"]
    )
```

## Error Handling

```python
from typing import Optional
import logging

logger = logging.getLogger(__name__)

def safe_add_documents(
    collection,
    documents: List[str],
    embeddings: List[List[float]],
    metadatas: List[Dict],
    ids: List[str]
) -> bool:
    """Safely add documents with error handling."""
    try:
        collection.add(
            documents=documents,
            embeddings=embeddings,
            metadatas=metadatas,
            ids=ids
        )
        return True
    except Exception as e:
        logger.error(f"Failed to add documents: {e}")
        return False

def safe_query(
    collection,
    query_embedding: List[float],
    n_results: int = 5
) -> Optional[Dict]:
    """Safely query with error handling."""
    try:
        return collection.query(
            query_embeddings=[query_embedding],
            n_results=n_results,
            include=["documents", "metadatas", "distances"]
        )
    except Exception as e:
        logger.error(f"Query failed: {e}")
        return None
```

## Monitoring

### Key Metrics

```python
def get_metrics(collection) -> Dict:
    """Get collection metrics."""
    return {
        "total_documents": collection.count(),
        "collection_name": collection.name,
        "metadata": collection.metadata,
        "timestamp": datetime.now().isoformat()
    }
```

### Health Checks

```python
def health_check(client) -> bool:
    """Check ChromaDB health."""
    try:
        client.heartbeat()
        return True
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return False
```

## Testing

### Unit Tests

```python
import pytest

def test_add_document(test_collection):
    """Test adding a document."""
    test_collection.add(
        ids=["test_1"],
        documents=["Test document"],
        embeddings=[[0.1] * 384],
        metadatas=[{"source": "test"}]
    )
    
    assert test_collection.count() == 1

def test_query_document(test_collection):
    """Test querying documents."""
    # Add test data
    test_collection.add(
        ids=["test_1"],
        documents=["Test document"],
        embeddings=[[0.1] * 384],
        metadatas=[{"source": "test"}]
    )
    
    # Query
    results = test_collection.query(
        query_embeddings=[[0.1] * 384],
        n_results=1
    )
    
    assert len(results["ids"][0]) == 1
    assert results["documents"][0][0] == "Test document"
```

## References

- [ChromaDB Documentation](https://docs.trychroma.com/)
- [ChromaDB GitHub](https://github.com/chroma-core/chroma)
- [Vector Database Best Practices](https://www.pinecone.io/learn/vector-database/)
