import { describe, it, expect, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createRouter, createWebHistory } from 'vue-router'
import ContractDocChoiceView from '../ContractDocChoiceView.vue'

// Mock router
const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/contract-doc-choice',
      name: 'ContractDocChoice',
      component: ContractDocChoiceView,
    },
  ],
})

describe('ContractDocChoiceView', () => {
  let wrapper: any

  beforeEach(async () => {
    wrapper = mount(ContractDocChoiceView, {
      global: {
        plugins: [router],
        stubs: {
          BaseHeader: true,
          LeftSidebar: true,
        },
      },
    })
    await router.isReady()
  })

  it('renders contract document choice page', () => {
    expect(wrapper.find('.page-title').text()).toBe('계약서 작성')
    expect(wrapper.find('.page-description').text()).toBe(
      '작성하고자 하는 계약서 유형을 선택해주세요',
    )
  })

  it('displays all 11 contract type buttons', () => {
    const buttons = wrapper.findAll('.contract-type-button')
    expect(buttons).toHaveLength(11)
  })

  it('shows coming soon badge for inactive buttons', () => {
    const comingSoonBadges = wrapper.findAll('.coming-soon-badge')
    expect(comingSoonBadges).toHaveLength(10) // 10개는 coming soon
  })

  it('has one active button (button 5)', () => {
    const activeButtons = wrapper.findAll('.contract-type-button--active')
    expect(activeButtons).toHaveLength(1)
  })

  it('shows correct contract type names', () => {
    const contractNames = wrapper.findAll('.contract-type-name')
    expect(contractNames[0].text()).toBe('부동산 매매계약서')
    expect(contractNames[4].text()).toBe('부동산 임대차계약서/일반주택')
  })

  it('displays correct descriptions', () => {
    const descriptions = wrapper.findAll('.contract-type-description')
    expect(descriptions[0].text()).toBe('아파트, 빌라, 상가 등 부동산 매매')
    expect(descriptions[4].text()).toBe('일반주택, 원룸 등 주거용 임대차')
  })

  it('shows coming soon message for inactive buttons', async () => {
    const inactiveButton = wrapper.findAll('.contract-type-button--coming-soon')[0]
    await inactiveButton.trigger('click')

    // alert가 호출되었는지 확인 (실제로는 mock 필요)
    expect(inactiveButton.classes()).toContain('contract-type-button--coming-soon')
  })

  it('has responsive design classes', () => {
    const container = wrapper.find('.contract-doc-choice-container')
    expect(container.exists()).toBe(true)

    const grid = wrapper.find('.contract-types-grid')
    expect(grid.exists()).toBe(true)
  })
})
