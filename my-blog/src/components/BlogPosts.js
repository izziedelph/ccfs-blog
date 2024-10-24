import React, { useState, useEffect } from 'react';

function BlogPosts() {
  const [posts, setPosts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchPosts = async () => {
      try {
        const response = await fetch(process.env.REACT_APP_API_URL);
        const data = await response.json();
        setPosts(data.posts || []);
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };

    fetchPosts();
  }, []);

  if (loading) return <div className="text-center py-4">Loading...</div>;
  if (error) return <div className="text-red-500 text-center py-4">Error: {error}</div>;

  return (
    <div className="space-y-6">
      {posts.map((post) => (
        <article key={post.PostID} className="bg-white rounded-lg shadow-lg overflow-hidden">
          <div className="p-6">
            <h2 className="text-2xl font-bold mb-2">{post.title}</h2>
            <div className="text-sm text-gray-500 mb-4">
              By {post.author} • {new Date(post.dateCreated).toLocaleDateString()}
            </div>
            <p className="text-gray-700">{post.content}</p>
          </div>
        </article>
      ))}
    </div>
  );
}

export default BlogPosts;