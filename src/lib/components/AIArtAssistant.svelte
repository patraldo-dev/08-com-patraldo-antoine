<!-- src/lib/components/AIArtAssistant.svelte -->
<script>
  import { t } from '$lib/i18n';
  
  let isOpen = $state(false);
  let messages = $state([]);
  let inputText = $state('');
  let isLoading = $state(false);
  let currentArtwork = $state(null);
  
  // Suggested questions
  const suggestedQuestions = [
    { key: 'inspiration', icon: '💡' },
    { key: 'technique', icon: '🎨' },
    { key: 'process', icon: '⚙️' },
    { key: 'similar', icon: '🔍' }
  ];
  
  async function sendMessage(text = inputText) {
    if (!text.trim() || isLoading) return;
    
    const userMessage = { role: 'user', content: text };
    messages = [...messages, userMessage];
    inputText = '';
    isLoading = true;
    
    try {
      const response = await fetch('/api/ai-assistant', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          message: text,
          artworkId: currentArtwork?.id,
          conversationHistory: messages.slice(-6) // Last 3 exchanges
        })
      });
      
      if (!response.ok) throw new Error('Failed to get response');
      
      const data = await response.json();
      messages = [...messages, { role: 'assistant', content: data.response }];
      
    } catch (error) {
      console.error('Assistant error:', error);
      messages = [...messages, { 
        role: 'assistant', 
        content: $t('assistant.error')
      }];
    } finally {
      isLoading = false;
    }
  }
  
  function askSuggested(questionKey) {
    const question = $t(`assistant.suggested.${questionKey}`);
    sendMessage(question);
  }
  
  function toggleAssistant(artwork = null) {
    isOpen = !isOpen;
    currentArtwork = artwork;

    if (isOpen && messages.length === 0) {
      // Welcome message
      messages = [{
        role: 'assistant',
        content: currentArtwork
          ? $t('assistant.welcomeArtwork', { title: currentArtwork.display_name || currentArtwork.title })
          : $t('assistant.welcomeGeneral')
      }];
    }
  }

  function handleKeydown(event) {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault();
      sendMessage();
    }
  }

  function clearConversation() {
    messages = [{
      role: 'assistant',
      content: currentArtwork
        ? $t('assistant.welcomeArtwork', { title: currentArtwork.display_name || currentArtwork.title })
        : $t('assistant.welcomeGeneral')
    }];
  }
  
  // Expose toggle function for parent components
  export function open(artwork) {
    toggleAssistant(artwork);
  }
</script>

<!-- Floating Assistant Button -->
<button 
  class="assistant-fab" 
  onclick={() => toggleAssistant()}
  aria-label={$t('assistant.openLabel')}
  title={$t('assistant.title')}
>
  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
    <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path>
  </svg>
</button>

<!-- Assistant Modal -->
{#if isOpen}
  <div class="assistant-overlay" onclick={() => toggleAssistant()}>
    <div class="assistant-modal" onclick={(e) => e.stopPropagation()}>
      <div class="assistant-header">
        <div class="header-content">
          <h2>{$t('assistant.title')}</h2>
          {#if currentArtwork}
            <p class="context-info">{$t('assistant.discussing')}: <strong>{currentArtwork.display_name || currentArtwork.title}</strong></p>
          {/if}
        </div>
        <div class="header-actions">
          <button class="icon-btn" onclick={clearConversation} title={$t('assistant.clearChat')}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <polyline points="1 4 1 10 7 10"></polyline>
              <path d="M3.51 15a9 9 0 1 0 2.13-9.36L1 10"></path>
            </svg>
          </button>
          <button class="icon-btn" onclick={() => toggleAssistant()} aria-label={$t('assistant.closeLabel')}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="18" y1="6" x2="6" y2="18"></line>
              <line x1="6" y1="6" x2="18" y2="18"></line>
            </svg>
          </button>
        </div>
      </div>
      
      <div class="messages-container">
        {#each messages as message}
          <div class="message {message.role}">
            <div class="message-avatar">
              {#if message.role === 'assistant'}
                🎨
              {:else}
                👤
              {/if}
            </div>
            <div class="message-content">
              {message.content}
            </div>
          </div>
        {/each}
        
        {#if isLoading}
          <div class="message assistant">
            <div class="message-avatar">🎨</div>
            <div class="message-content typing">
              <span></span><span></span><span></span>
            </div>
          </div>
        {/if}
      </div>
      
      {#if messages.length <= 1}
        <div class="suggestions">
          <p class="suggestions-title">{$t('assistant.suggestionsTitle')}</p>
          <div class="suggestions-grid">
            {#each suggestedQuestions as suggestion}
              <button class="suggestion-btn" onclick={() => askSuggested(suggestion.key)}>
                <span class="suggestion-icon">{suggestion.icon}</span>
                <span class="suggestion-text">{$t(`assistant.suggested.${suggestion.key}`)}</span>
              </button>
            {/each}
          </div>
        </div>
      {/if}
      
      <div class="input-container">
        <textarea
          bind:value={inputText}
          onkeydown={handleKeydown}
          placeholder={$t('assistant.inputPlaceholder')}
          disabled={isLoading}
          rows="1"
        ></textarea>
        <button 
          class="send-btn" 
          onclick={() => sendMessage()}
          disabled={!inputText.trim() || isLoading}
          aria-label={$t('assistant.sendLabel')}
        >
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="22" y1="2" x2="11" y2="13"></line>
            <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
          </svg>
        </button>
      </div>
    </div>
  </div>
{/if}

<style>
  .assistant-fab {
    position: fixed;
    bottom: 2rem;
    right: 6rem; /* Positioned left of search button */
    width: 56px;
    height: 56px;
    border-radius: 50%;
    background: #1a1a1a;
    color: white;
    border: 2px solid #2a2a2a;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.2);
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.3s ease;
    z-index: 999;
  }
  
  .assistant-fab:hover {
    transform: scale(1.1);
    background: #2a2a2a;
    box-shadow: 0 6px 30px rgba(0, 0, 0, 0.3);
  }
  
  .assistant-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.7);
    backdrop-filter: blur(4px);
    z-index: 1000;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 1rem;
    animation: fadeIn 0.2s ease;
  }
  
  @keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
  }
  
  .assistant-modal {
    background: white;
    border-radius: 16px;
    width: 100%;
    max-width: 600px;
    height: 80vh;
    display: flex;
    flex-direction: column;
    box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
    animation: slideUp 0.3s ease;
  }
  
  @keyframes slideUp {
    from {
      opacity: 0;
      transform: translateY(20px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }
  
  .assistant-header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    padding: 1.5rem;
    border-bottom: 1px solid #e0e0e0;
  }
  
  .header-content h2 {
    margin: 0 0 0.25rem 0;
    font-size: 1.25rem;
    font-weight: 600;
    color: #1a1a1a;
  }
  
  .context-info {
    margin: 0;
    font-size: 0.875rem;
    color: #666;
  }
  
  .header-actions {
    display: flex;
    gap: 0.5rem;
  }
  
  .icon-btn {
    background: none;
    border: none;
    cursor: pointer;
    padding: 0.5rem;
    color: #666;
    transition: color 0.2s;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  
  .icon-btn:hover {
    color: #1a1a1a;
  }
  
  .messages-container {
    flex: 1;
    overflow-y: auto;
    padding: 1.5rem;
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }
  
  .message {
    display: flex;
    gap: 0.75rem;
    animation: messageIn 0.3s ease;
  }
  
  @keyframes messageIn {
    from {
      opacity: 0;
      transform: translateY(10px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }
  
  .message-avatar {
    flex-shrink: 0;
    width: 32px;
    height: 32px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 1.25rem;
  }
  
  .message-content {
    background: #f0f0f0;
    padding: 0.75rem 1rem;
    border-radius: 12px;
    line-height: 1.5;
    max-width: 80%;
  }
  
  .message.assistant .message-content {
    background: #1a1a1a;
    color: white;
  }
  
  .message.user {
    flex-direction: row-reverse;
  }
  
  .message.user .message-content {
    background: #e8f0fe;
  }
  
  .typing {
    display: flex;
    gap: 0.25rem;
    padding: 1rem;
  }
  
  .typing span {
    width: 8px;
    height: 8px;
    background: white;
    border-radius: 50%;
    animation: typing 1.4s infinite;
  }
  
  .typing span:nth-child(2) {
    animation-delay: 0.2s;
  }
  
  .typing span:nth-child(3) {
    animation-delay: 0.4s;
  }
  
  @keyframes typing {
    0%, 60%, 100% {
      opacity: 0.3;
      transform: scale(0.8);
    }
    30% {
      opacity: 1;
      transform: scale(1);
    }
  }
  
  .suggestions {
    padding: 0 1.5rem 1rem;
    border-top: 1px solid #f0f0f0;
  }
  
  .suggestions-title {
    font-size: 0.875rem;
    color: #666;
    margin: 1rem 0 0.75rem;
  }
  
  .suggestions-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 0.5rem;
  }
  
  .suggestion-btn {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.75rem;
    background: #f8f9fa;
    border: 1px solid #e0e0e0;
    border-radius: 8px;
    cursor: pointer;
    transition: all 0.2s;
    text-align: left;
    font-size: 0.875rem;
  }
  
  .suggestion-btn:hover {
    background: #e8f0fe;
    border-color: #1a1a1a;
  }
  
  .suggestion-icon {
    font-size: 1.25rem;
  }
  
  .input-container {
    display: flex;
    gap: 0.5rem;
    padding: 1.5rem;
    border-top: 1px solid #e0e0e0;
    background: #f8f9fa;
  }
  
  textarea {
    flex: 1;
    padding: 0.75rem;
    border: 2px solid #e0e0e0;
    border-radius: 8px;
    font-size: 1rem;
    font-family: inherit;
    resize: none;
    min-height: 44px;
    max-height: 120px;
  }
  
  textarea:focus {
    outline: none;
    border-color: #1a1a1a;
  }
  
  textarea:disabled {
    background: #f5f5f5;
    cursor: not-allowed;
  }
  
  .send-btn {
    flex-shrink: 0;
    width: 44px;
    height: 44px;
    background: #1a1a1a;
    color: white;
    border: none;
    border-radius: 8px;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.2s;
  }
  
  .send-btn:hover:not(:disabled) {
    background: #2a2a2a;
    transform: scale(1.05);
  }
  
  .send-btn:disabled {
    background: #ccc;
    cursor: not-allowed;
  }
  
  @media (max-width: 768px) {
    .assistant-fab {
      bottom: 5rem;
      right: 1rem;
      width: 48px;
      height: 48px;
    }
    
    .assistant-modal {
      height: 100vh;
      border-radius: 0;
      max-width: 100%;
    }
    
    .suggestions-grid {
      grid-template-columns: 1fr;
    }
  }
</style>
