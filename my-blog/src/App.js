import React from 'react';
import { Authenticator } from '@aws-amplify/ui-react';
import { Amplify } from 'aws-amplify';
import '@aws-amplify/ui-react/styles.css';
import BlogPosts from './components/BlogPosts';
import CreatePost from './components/CreatePost';

Amplify.configure({
  Auth: {
    region: 'us-east-1',
    userPoolId: process.env.REACT_APP_USER_POOL_ID,
    userPoolWebClientId: process.env.REACT_APP_USER_POOL_CLIENT_ID,
  }
});

function App() {
  return (
    <Authenticator>
      {({ signOut, user }) => (
        <div className="min-h-screen bg-gray-50">
          <header className="bg-blue-600 shadow-lg">
            <div className="max-w-7xl mx-auto py-6 px-4 flex justify-between items-center">
              <div>
                <h1 className="text-3xl font-bold text-white">CCFS Blog</h1>
                <p className="text-blue-100 mt-1">Share Your Island Food Adventures!</p>
              </div>
              <div className="flex items-center space-x-4">
                <span className="text-white">{user.attributes.email}</span>
                <button
                  onClick={signOut}
                  className="bg-red-500 text-white px-4 py-2 rounded hover:bg-red-600"
                >
                  Sign Out
                </button>
              </div>
            </div>
          </header>
          <main className="max-w-7xl mx-auto py-6 px-4">
            <CreatePost user={user} />
            <BlogPosts />
          </main>
          <footer className="bg-gray-100 mt-12">
            <div className="max-w-7xl mx-auto py-4 px-4 text-center text-gray-600">
              <p>© 2024 CCFS Blog - Island Food Stories</p>
            </div>
          </footer>
        </div>
      )}
    </Authenticator>
  );
}

export default App;