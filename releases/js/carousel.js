
function initCarousel(containerId, trackId) {
    const container = document.getElementById(containerId);
    const track = document.getElementById(trackId);
    let scrollAmount = 1;
    let direction = 1;

    function scrollCarousel() {
        if (container.scrollWidth <= container.clientWidth) return;

        if ((direction === 1 && container.scrollLeft + container.clientWidth >= track.scrollWidth) ||
            (direction === -1 && container.scrollLeft <= 0)) {
            direction *= -1;
        }
        container.scrollLeft += scrollAmount * direction;
    }

    let interval = setInterval(scrollCarousel, 20);

    container.addEventListener("mouseenter", () => clearInterval(interval));
    container.addEventListener("mouseleave", () => interval = setInterval(scrollCarousel, 20));
}
