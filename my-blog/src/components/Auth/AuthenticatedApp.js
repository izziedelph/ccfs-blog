import React from 'react';
import { useAuth } from '../../contexts/AuthContext';
import BlogPosts from '../BlogPosts';
import CreatePost from '../CreatePost';

function AuthenticatedApp() {
  const { user, signOut } = useAuth();

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-blue-600 shadow-lg">
        <div className="max-w-7xl mx-auto py-6 px-4 flex justify-between items-center">
          <div>
            <h1 className="text-3xl font-bold text-white">CCFS Blog</h1>
            <p className="text-blue-100 mt-1">Share Your Island Food Adventures!</p>
          </div>
          <div className="flex items-center space-x-4">
            <span className="text-white">
              {user.attributes.email}
            </span>
            <button
              onClick={signOut}
              className="bg-red-500 text-white px-4 py-2 rounded hover:bg-red-600 transition-colors"
            >
              Sign Out
            </button>
          </div>
        </div>
      </header>
      <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <CreatePost />
        <div className="mt-8">
          <BlogPosts />
        </div>
      </main>
      <footer className="bg-gray-100 mt-12">
        <div className="max-w-7xl mx-auto py-4 px-4 text-center text-gray-600">
          <p>© 2024 CCFS Blog - Island Food Stories</p>
        </div>
      </footer>
    </div>
  );
}

export default AuthenticatedApp;