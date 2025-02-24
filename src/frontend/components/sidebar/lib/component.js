import { Component } from 'component'
import { sidebarObservable } from './sidebarObservable'

const COLLAPSED_CLASS = 'sidebar--collapsed'
const EXPANDED_CLASS = 'main--expanded'
const KEY_NAV_STATE = 'main-menu::state'
const NAV_STATE_EXPANDED = 'expanded'
const NAV_STATE_COLLAPSED = 'collapsed'

class SidebarComponent extends Component {
    constructor(element)  {
        super(element)
        this.el = $(this.element)
        this.isMobile = this.isMobileResolution()
        this.toggle = this.el.find('.sidebar__toggle')
        this.currentState = localStorage.getItem(KEY_NAV_STATE) || (this.isMobile ? NAV_STATE_COLLAPSED : NAV_STATE_EXPANDED)

        this.initSidebar()
    }

    initSidebar() {
        const sidebarToggle = this.el.find('.sidebar__toggle')
        sidebarObservable.addSubscriber(this)

        if (!sidebarToggle) {
            return
        }

        if (this.isMobile) {
          this.collapseSidebar()
        } else {
          this.currentState === NAV_STATE_COLLAPSED ? this.collapseSidebar() : this.expandSidebar()
        }

        $(window).on("resize",() => { this.handleResize() })

        sidebarToggle.on("click", () => { this.handleClick() })
    }

    handleResize() {
        if (this.isMobileResolution()) {
            if (!this.isMobile) {
                this.collapseSidebar()
                this.isMobile = true
            }
        } else {
            if (this.isMobile) {
                this.expandSidebar()
                this.isMobile = false
            }
        }
    }

    handleClick() {
        if (this.el.hasClass(COLLAPSED_CLASS)) {
            this.expandSidebar()
        } else {
            this.collapseSidebar()
        }
        sidebarObservable.sideBarChange()
    }

    collapseSidebar() {
        $("main").addClass(EXPANDED_CLASS)
        this.el.addClass(COLLAPSED_CLASS)
        $(this.toggle).attr('aria-expanded','false')

        if (!this.isMobile) {
            this.currentState = NAV_STATE_COLLAPSED
            localStorage.setItem(KEY_NAV_STATE, this.currentState)
        }
    }

    expandSidebar() {
        $("main").removeClass(EXPANDED_CLASS)
        this.el.removeClass(COLLAPSED_CLASS)
        $(this.toggle).attr('aria-expanded','true')

        if (!this.isMobile) {
            this.currentState = NAV_STATE_EXPANDED
            localStorage.setItem(KEY_NAV_STATE, this.currentState)
        }
    }

    isMobileResolution() {
        return window.matchMedia("(max-width: 991px)").matches
    }
}

export default SidebarComponent
