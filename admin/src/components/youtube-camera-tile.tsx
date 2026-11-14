export function YoutubeCameraTile({ index = 0 }: { index?: number }) {
  return (
    <article className="cctv-sample-card">
      <div className="cctv-recording">
        <iframe
          className="cctv-passive-player"
          src="https://www.youtube-nocookie.com/embed/CJ3dAAna7jQ?autoplay=1&mute=1&loop=1&playlist=CJ3dAAna7jQ&playsinline=1&rel=0&controls=0&fs=0&disablekb=1&iv_load_policy=3"
          title={`Sample CCTV video · view ${index + 1}`}
          loading="lazy"
          allow="autoplay; encrypted-media"
          tabIndex={-1}
          referrerPolicy="strict-origin-when-cross-origin"
        />
      </div>
      <div className="cctv-sample-content">
        <div className="cctv-source-row">
          <span>Sample view {String(index + 1).padStart(2, "0")}</span>
          <a href="https://youtu.be/CJ3dAAna7jQ" target="_blank" rel="noopener noreferrer">Watch on YouTube</a>
        </div>
      </div>
    </article>
  );
}
