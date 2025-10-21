// src/lib/actions/clickOutside.js
/** 
 * Close element when clicking outside
 * @param {HTMLElement} node 
 * @param {() => void} callback 
 */
export function clickOutside(node, callback) {
  const handleClick = (event) => {
    if (!node.contains(event.target)) {
      callback();
    }
  };

  document.addEventListener('click', handleClick, true);

  return {
    destroy() {
      document.removeEventListener('click', handleClick, true);
    }
  };
}
