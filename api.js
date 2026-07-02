async function getTerbaru() {
    const res = await fetch('/api/terbaru');
    return await res.json();
}

async function getTrending() {
    const res = await fetch('/api/trending');
    return await res.json();
}

async function searchAnime(query) {
    const res = await fetch(
        `/api/search?q=${encodeURIComponent(query)}`
    );

    return await res.json();
}